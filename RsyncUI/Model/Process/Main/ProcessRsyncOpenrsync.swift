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
    var sequenceTerminationTask: Task<Void, Never>?

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
        // Pipe for reading output from Process
        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = pipe
        let outHandle = pipe.fileHandleForReading
        outHandle.waitForDataInBackgroundAndNotify()

        // AsyncSequence
        let sequencefilehandler = NotificationCenter.default.notifications(
            named: NSNotification.Name.NSFileHandleDataAvailable,
            object: outHandle
        )
        let sequencetermination = NotificationCenter.default.notifications(
            named: Process.didTerminateNotification,
            object: task
        )

        sequenceFileHandlerTask = Task {
            for await _ in sequencefilehandler {
                await self.datahandle(pipe)
            }
        }

        sequenceTerminationTask = Task {
            for await _ in sequencetermination {
                Logger.process.info("ProcessRsyncOpenrsync: Process terminated - starting potensial drain")
                sequenceFileHandlerTask?.cancel()
                try? await Task.sleep(nanoseconds: 50_000_000)
                var totalDrained = 0
                while true {
                    let data: Data = pipe.fileHandleForReading.availableData
                    if data.isEmpty {
                        Logger.process.info("ProcessRsyncOpenrsync: Drain complete - \(totalDrained) bytes total")
                        break
                    }

                    totalDrained += data.count
                    Logger.process.info("ProcessRsyncOpenrsync: Draining \(data.count) bytes")

                    // IMPORTANT: Actually process the drained data
                    if let text = String(data: data, encoding: .utf8) {
                        // Logger.process.info("ProcessRsyncOpenrsync: Drained text: \(text)")
                        self.output.append(text)
                    }
                }

                await self.termination()
            }
        }

        SharedReference.shared.process = task
        do {
            try task.run()
        } catch let e {
            let error = e
            propogateerror(error: error)
        }
        if let launchPath = task.launchPath, let arguments = task.arguments {
            Logger.process.info("ProcessRsyncOpenrsync: command - \(launchPath, privacy: .public)")
            Logger.process.info("ProcessRsyncOpenrsync: arguments - \(arguments.joined(separator: "\n"), privacy: .public)")
        }
    }

    func propogateerror(error: Error) {
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
        Logger.process.info("ProcessRsyncOpenrsync: DEINIT")
    }
}

extension ProcessRsyncOpenrsync {
    func datahandle(_ pipe: Pipe) async {
        let outHandle = pipe.fileHandleForReading
        let data = outHandle.availableData
        if data.count > 0 {
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
                            self.propogateerror(error: error)
                        }
                    }
                }
                // Send message about files
                if usefilehandler {
                    filehandler(output.count)
                }
            }
            outHandle.waitForDataInBackgroundAndNotify()
        }
    }

    func termination() async {
        processtermination(output, config?.hiddenID)
        // Log error in rsync output to file
        if errordiscovered, let config {
            Task {
                await ActorLogToFile(command: config.backupID,
                                     stringoutputfromrsync: output)
            }
        }
        SharedReference.shared.process = nil
        // Cancel Tasks
        sequenceFileHandlerTask?.cancel()
        sequenceTerminationTask?.cancel()

        Logger.process.info("ProcessRsyncOpenrsync: process = nil and termination discovered \(Thread.isMain, privacy: .public) but on \(Thread.current, privacy: .public)")
    }
}
