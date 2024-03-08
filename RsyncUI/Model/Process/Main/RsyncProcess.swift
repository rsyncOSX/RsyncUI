//
//  RsyncProcess.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 15/03/2021.
//

import Combine
import Foundation
import OSLog
import ShellOut

final class RsyncProcess {
    // Combine subscribers
    var subscriptons = Set<AnyCancellable>()
    // Process termination and filehandler closures
    var processtermination: ([String]?, Int?) -> Void
    var filehandler: (Int) -> Void
    // Verify network connection
    var config: SynchronizeConfiguration?
    var monitor: NetworkMonitor?
    // Arguments to command
    var arguments: [String]?
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

    private func localfilehandler() -> Int {
        return outputprocess?.getOutput()?.count ?? 0
    }

    func executeProcess() {
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
            .sink { [self] _ in
                let data = outHandle.availableData
                if data.count > 0 {
                    if let str = NSString(data: data, encoding: String.Encoding.utf8.rawValue) {
                        self.outputprocess?.addlinefromoutput(str: str as String)
                        // Send message about files
                        self.filehandler(self.outputprocess?.getOutput()?.count ?? 0)
                    }
                    outHandle.waitForDataInBackgroundAndNotify()
                }
            }.store(in: &subscriptons)
        // Combine, subscribe to Process.didTerminateNotification
        NotificationCenter.default.publisher(
            for: Process.didTerminateNotification)
            .debounce(for: .milliseconds(500), scheduler: globalMainQueue)
            .sink { [self] _ in
                self.processtermination(self.outputprocess?.getOutput(), self.config?.hiddenID)
                // Logg to file
                _ = Logfile(TrimTwo(outputprocess?.getOutput() ?? []).trimmeddata, error: false)
                // Release Combine subscribers
                subscriptons.removeAll()
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
            Logger.process.info("RsyncProcess: \(launchPath, privacy: .public)")
            Logger.process.info("RsyncProcess: \(arguments.joined(separator: "\n"), privacy: .public)")
        }
    }

    // Terminate Process, used when user Aborts task.
    func abortProcess() {
        _ = InterruptProcess()
    }

    init(arguments: [String]?,
         config: SynchronizeConfiguration?,
         processtermination: @escaping ([String]?, Int?) -> Void,
         filehandler: @escaping (Int) -> Void)
    {
        self.arguments = arguments
        self.processtermination = processtermination
        self.filehandler = filehandler
        self.config = config
        if let config = self.config {
            if config.pretask?.isEmpty == false, config.executepretask == 1 {
                shelloutpretask = true
                Logger.process.info("RsyncProcessAsync: Pre SHELLOUT true")
            } else {
                shelloutpretask = false
            }
            if config.posttask?.isEmpty == false, config.executeposttask == 1 {
                shelloutpretask = true
                Logger.process.info("RsyncProcessAsync: Post SHELLOUT true")
            } else {
                shelloutpretask = false
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
        Logger.process.info("RsyncProcess: DEINIT")
    }
}

extension RsyncProcess {
    func propogateerror(error: Error) {
        SharedReference.shared.errorobject?.alert(error: error)
    }

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
