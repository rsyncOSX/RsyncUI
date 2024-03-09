//
//  RsyncProcessAsync.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 15/03/2021.
//
// swiftlint:disable function_body_length

import Combine
import Foundation
import OSLog
import ShellOut

final class RsyncProcessAsync {
    // Combine subscribers
    var subscriptons = Set<AnyCancellable>()
    // Verify network connection
    var config: SynchronizeConfiguration?
    var monitor: NetworkMonitor?
    // Arguments to command
    var arguments: [String]?
    // Process termination
    var processtermination: ([String]?, Int?) -> Void
    // Output
    var outputprocess: OutputfromProcess?
    // ShellOut
    var shelloutpretask: Bool = false
    var shelloutposttask: Bool = false

    func executemonitornetworkconnection() {
        guard config?.offsiteServer.isEmpty == false else { return }
        guard SharedReference.shared.monitornetworkconnection == true else { return }
        monitor = NetworkMonitor()
        monitor?.netStatusChangeHandler = { [unowned self] in
            do {
                try statusDidChange()
            } catch let e {
                let error = e
                propogateerror(error: error)
            }
        }
    }

    // Throws error
    func statusDidChange() throws {
        if monitor?.monitor?.currentPath.status != .satisfied {
            _ = InterruptProcess()
            throw Networkerror.networkdropped
        }
    }

    @MainActor
    func executeProcess() async {
        // Must check valid rsync exists
        guard SharedReference.shared.norsync == false else { return }
        // Process
        let task = Process()
        // Getting version of rsync
        task.launchPath = GetfullpathforRsync().rsyncpath
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
        // Combine, subscribe to NSNotification.Name.NSFileHandleDataAvailable
        NotificationCenter.default.publisher(
            for: NSNotification.Name.NSFileHandleDataAvailable)
            .sink { _ in
                let data = outHandle.availableData
                if data.count > 0 {
                    if let str = NSString(data: data, encoding: String.Encoding.utf8.rawValue) {
                        self.outputprocess?.addlinefromoutput(str: str as String)
                    }
                    outHandle.waitForDataInBackgroundAndNotify()
                }
            }.store(in: &subscriptons)
        // Combine, subscribe to Process.didTerminateNotification
        NotificationCenter.default.publisher(
            for: Process.didTerminateNotification)
            .debounce(for: .milliseconds(500), scheduler: globalMainQueue)
            .sink { _ in
                // Process termination and Log to file
                self.processtermination(self.outputprocess?.getOutput(), self.config?.hiddenID)
                _ = Logfile(TrimTwo(self.outputprocess?.getOutput() ?? []).trimmeddata, error: false)
                // Release Combine subscribers
                self.subscriptons.removeAll()
                // Execute posttask
                if self.shelloutposttask {
                    Task {
                        try await self.executeposttask()
                    }
                }
            }.store(in: &subscriptons)
        SharedReference.shared.process = task
        // Execute pretask
        if shelloutpretask {
            do {
                Task {
                    try await executepretask()
                }
            }
        }

        do {
            try task.run()
        } catch let e {
            let error = e
            propogateerror(error: error)
        }
        if let launchPath = task.launchPath, let arguments = task.arguments {
            Logger.process.info("RsyncProcessAsync: \(launchPath, privacy: .public)")
            Logger.process.info("RsyncProcessAsync: \(arguments.joined(separator: "\n"), privacy: .public)")
        }
    }

    // Terminate Process, used when user Aborts task.
    func abortProcess() {
        _ = InterruptProcess()
    }

    init(arguments: [String]?,
         config: SynchronizeConfiguration?,
         processtermination: @escaping ([String]?, Int?) -> Void)
    {
        self.arguments = arguments
        self.processtermination = processtermination
        self.config = config
        if let config = self.config {
            if config.pretask?.isEmpty == false, config.executepretask == 1 {
                shelloutpretask = true
                Logger.process.info("RsyncProcessAsync: Pre SHELLOUT true")
            } else {
                shelloutpretask = false
            }
            if config.posttask?.isEmpty == false, config.executeposttask == 1 {
                shelloutposttask = true
                Logger.process.info("RsyncProcessAsync: Post SHELLOUT true")
            } else {
                shelloutposttask = false
            }
            outputprocess = OutputfromProcess()
            executemonitornetworkconnection()
        } else {
            return
        }
    }

    deinit {
        self.monitor?.stopMonitoring()
        self.monitor = nil
        SharedReference.shared.process = nil
        Logger.process.info("RsyncProcessAsync: DEINIT")
    }
}

extension RsyncProcessAsync {
    func propogateerror(error: Error) {
        SharedReference.shared.errorobject?.alert(error: error)
    }

    @MainActor
    func executepretask() async throws {
        if let pretask = config?.pretask {
            do {
                try await shellOut(to: pretask)
            } catch let e {
                let error = e as? ShellOutError
                Logger.process.critical("Pretask failed: \(pretask, privacy: .public) \(error, privacy: .public)")
            }
            Logger.process.info("Executed pretask: \(pretask, privacy: .public)")
        }
    }

    @MainActor
    func executeposttask() async throws {
        if let posttask = config?.posttask {
            do {
                try await shellOut(to: posttask)
            } catch let e {
                let error = e as? ShellOutError
                Logger.process.critical("Posttask failed: \(posttask, privacy: .public) \(error, privacy: .public)")
            }
            Logger.process.info("Executed posttask: \(posttask, privacy: .public)")
        }
    }
}

// swiftlint:enable function_body_length
