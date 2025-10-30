//
//  ProcessRsyncOpenrsync.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 11/09/2025.
//

import Foundation
import OSLog

@MainActor
final class ProcessRsyncOpenrsync {
    // Process termination and filehandler closures
    var processtermination: ([String]?, Int?) -> Void
    var filehandler: (Int) -> Void
    var config: SynchronizeConfiguration?
    // Arguments to command
    var arguments: [String]?
    // Output
    var output = [String]()
    // Use filehandler
    var usefilehandler: Bool = false
    // Check for error
    var checklineforerror: TrimOutputFromRsync?
    var errordiscovered: Bool = false
    // Tasks
    var sequenceFileHandlerTask: Task<Void, Never>?
    var waitForExitTask: Task<Void, Never>?
    
    // Keep references so termination can drain remaining data reliably
    private var pipe: Pipe?
    private var outHandle: FileHandle?

    // Ensure termination is handled only once (guard against both terminationHandler and waitUntilExit firing)
    private var terminationHandled: Bool = false

    func executeProcess() {
        // Must check valid rsync exists
        guard SharedReference.shared.norsync == false else { return }
        guard config?.task != SharedReference.shared.halted else { return }

        // Process
        let task = Process()

        // Getting version of rsync
        task.launchPath = GetfullpathforRsync().rsyncpath()
        guard task.launchPath != nil else { return }
        task.arguments = arguments

        // If there are any Environmentvariables like
        // SSH_AUTH_SOCK": "/Users/user/.gnupg/S.gpg-agent.ssh"
        if let environment = MyEnvironment() {
            task.environment = environment.environment
        }

        // Pipe for reading output from Process (stdout + stderr merged)
        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = pipe
        let outHandle = pipe.fileHandleForReading
        outHandle.waitForDataInBackgroundAndNotify()

        // store for termination final drain
        self.pipe = pipe
        self.outHandle = outHandle

        // Create AsyncSequence scoped to this specific file handle
        let fileNotifications = NotificationCenter.default.notifications(
            named: NSNotification.Name.NSFileHandleDataAvailable,
            object: outHandle
        )

        // IMPORTANT: capture self strongly here so the instance remains alive for the full lifetime
        // of the streaming Task. This prevents early deinit which previously prevented termination()
        // from running. The Task will complete on process exit and then release self.
        sequenceFileHandlerTask = Task {
            // strong capture of self (no [weak self])
            for await _ in fileNotifications {
                await self.datahandle(pipe)
            }
            // Final drain - keep reading until no more data (availableData returns empty when EOF)
            while outHandle.availableData.count > 0 {
                await self.datahandle(pipe)
            }
        }

        // Use Process.terminationHandler to reliably detect termination for this specific Process.
        // Set before starting the process so we don't miss a quick exit.
        task.terminationHandler = { [weak self] _ in
            // Run asynchronously so we don't block whatever thread calls terminationHandler.
            Task.detached { [weak self] in
                // Small delay to let final data arrive (matches previous behavior)
                // try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
                await MainActor.run { [weak self] in
                    guard let self, !self.terminationHandled else { return }
                    terminationHandled = true
                    Task { await self.termination() }
                }
            }
        }

        // Fallback: also spawn a detached task that blocks on waitUntilExit.
        // This ensures we catch termination even if terminationHandler is missed for any reason.
        waitForExitTask = Task.detached { [weak self, weak task] in
            guard let task else { return }
            // This will block the current thread until the process exits.
            task.waitUntilExit()
            // small delay consistent with previous logic to allow final data arrival
            // try? await Task.sleep(nanoseconds: 100_000_000)
            await MainActor.run { [weak self] in
                guard let self, !self.terminationHandled else { return }
                terminationHandled = true
                Task { await self.termination() }
            }
        }

        SharedReference.shared.process = task
        do {
            try task.run()
        } catch let e {
            let error = e
            propagateError(error: error)
        }
        if let launchPath = task.launchPath, let arguments = task.arguments {
            Logger.process.info("ProcessRsyncOpenrsync: \(launchPath, privacy: .public)")
            Logger.process.info("ProcessRsyncOpenrsync: \(arguments.joined(separator: "\n"), privacy: .public)")
        }
    }

    func propagateError(error: Error) {
        SharedReference.shared.errorobject?.alert(error: error)
    }

    init(arguments: [String]?,
         config: SynchronizeConfiguration?,
         processtermination: @escaping ([String]?, Int?) -> Void,
         filehandler: @escaping (Int) -> Void,
         usefilehandler: Bool)
    {
        self.arguments = arguments
        self.processtermination = processtermination
        self.filehandler = filehandler
        self.usefilehandler = usefilehandler

        if let config {
            self.config = config
        }
        if SharedReference.shared.checkforerrorinrsyncoutput {
            checklineforerror = TrimOutputFromRsync()
        }
    }

    convenience init(arguments: [String]?,
                     config: SynchronizeConfiguration?,
                     processtermination: @escaping ([String]?, Int?) -> Void,
                     filehandler: @escaping (Int) -> Void)
    {
        self.init(arguments: arguments,
                  config: config,
                  processtermination: processtermination,
                  filehandler: filehandler,
                  usefilehandler: true)
    }

    convenience init(arguments: [String]?,
                     config: SynchronizeConfiguration?,
                     processtermination: @escaping ([String]?, Int?) -> Void)
    {
        // To satisfy arguments
        let filehandler: (Int) -> Void = { _ in
            Logger.process.info("ProcessRsyncOpenrsync: You should NOT SEE this message")
        }
        self.init(arguments: arguments,
                  config: config,
                  processtermination: processtermination,
                  filehandler: filehandler,
                  usefilehandler: false)
    }

    convenience init(arguments: [String]?,
                     processtermination: @escaping ([String]?, Int?) -> Void)
    {
        // To satisfy arguments
        let filehandler: (Int) -> Void = { _ in
            Logger.process.info("ProcessRsyncOpenrsync: You should not SEE this message")
        }
        self.init(arguments: arguments,
                  config: nil,
                  processtermination: processtermination,
                  filehandler: filehandler,
                  usefilehandler: false)
    }

    deinit {
        // Do not cancel the file handler task here — the Task intentionally retains `self`
        // until the process exits. Cancelling here would skip termination handling.
        waitForExitTask?.cancel()
        Logger.process.info("ProcessRsyncOpenrsync: DEINIT")
    }
}

extension ProcessRsyncOpenrsync {
    
    // Main data handler using NSString.enumerateLines (no partial-line buffering)
    func datahandle(_ pipe: Pipe) async {
        let outHandle = pipe.fileHandleForReading
        let data = outHandle.availableData
        guard data.count > 0 else { return }

        if let str = NSString(data: data, encoding: String.Encoding.utf8.rawValue) {
            str.enumerateLines { line, _ in
                self.output.append(line)
                if SharedReference.shared.checkforerrorinrsyncoutput,
                   self.errordiscovered == false
                {
                    do {
                        try self.checklineforerror?.checkforrsyncerror(line)
                    } catch let e {
                        self.errordiscovered = true
                        let error = e
                        self.propagateError(error: error)
                    }
                }
            }
            // Send message about files, do not report the last lines of status from rsync if
            // the real run is ongoing
            if usefilehandler {
                filehandler(output.count)
            }
        }

        outHandle.waitForDataInBackgroundAndNotify()
    }

    // Drain any remaining availableData from the stored outHandle and process lines using NSString.enumerateLines
    private func drainRemainingOutput() {
        guard let outHandle else { return }
        var data = outHandle.availableData
        while data.count > 0 {
            if let str = NSString(data: data, encoding: String.Encoding.utf8.rawValue) {
                str.enumerateLines { line, _ in
                    self.output.append(line)
                    if SharedReference.shared.checkforerrorinrsyncoutput,
                       self.errordiscovered == false
                    {
                        do {
                            try self.checklineforerror?.checkforrsyncerror(line)
                        } catch let e {
                            self.errordiscovered = true
                            let error = e
                            self.propagateError(error: error)
                        }
                    }
                }
            }
            data = outHandle.availableData
        }
    }

    func termination() async {
        // Final drain of remaining data in case notifications missed anything
        drainRemainingOutput()
        processtermination(output, config?.hiddenID)

        // Log error in rsync output to file
        if errordiscovered, let config {
            Task {
                await ActorLogToFile(command: config.backupID,
                                     stringoutputfromrsync: output)
            }
        }
        SharedReference.shared.process = nil

        // Cancel file handler task (this will also cause the NotificationCenter sequence to be released)
        sequenceFileHandlerTask?.cancel()
        waitForExitTask?.cancel()

        Logger.process.info("ProcessRsyncOpenrsync: process = nil and termination discovered \(Thread.isMain, privacy: .public) but on \(Thread.current, privacy: .public)")
    }
}
