//
//  RsyncProcessNOFilehandler.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 15/03/2021.
//
// swiftlint:disable function_body_length cyclomatic_complexity line_length

import Combine
import Foundation
import OSLog

final class RsyncProcessNOFilehandler: @unchecked Sendable {
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
            .debounce(for: .milliseconds(500), scheduler: DispatchQueue.main)
            .sink { _ in
                // Process termination and Log to file
                if self.config == nil {
                    self.processtermination(self.outputprocess?.getOutput(), -1)
                } else {
                    self.processtermination(self.outputprocess?.getOutput(), self.config?.hiddenID)
                }
                // Logg to file
                if self.arguments?.contains("--dry-run") == false, self.arguments?.contains("--version") == false {
                    _ = Logfile(TrimTwo(self.outputprocess?.getOutput() ?? []).trimmeddata, error: false)
                }
                // Release Combine subscribers
                self.subscriptons.removeAll()
            }.store(in: &subscriptons)
        SharedReference.shared.process = task
        do {
            try task.run()
        } catch let e {
            let error = e
            propogateerror(error: error)
        }
        if let launchPath = task.launchPath, let arguments = task.arguments {
            Logger.process.info("RsyncProcessNOFilehandler: \(launchPath, privacy: .public)")
            Logger.process.info("RsyncProcessNOFilehandler: \(arguments.joined(separator: "\n"), privacy: .public)")
        }

        if SharedReference.shared.monitornetworkconnection {
            Task {
                var sshport = 22
                if let port = config?.sshport {
                    sshport = port
                } else if let port = SharedReference.shared.sshport {
                    sshport = port
                }
                do {
                    let server = config?.offsiteServer ?? ""
                    if server.isEmpty == false {
                        Logger.process.info("RsyncProcessNOFilehandler: checking networkconnection")
                        _ = try await TCPconnections().asyncverifyTCPconnection(config?.offsiteServer ?? "", port: sshport)
                    }

                } catch let e {
                    let error = e
                    propogateerror(error: error)
                }
            }
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
        outputprocess = OutputfromProcess()
        // Only execute montornetwork connection if
        // a selected configuration
        if let config = config {
            self.config = config
            executemonitornetworkconnection()
        }
    }

    convenience init(arguments: [String]?,
                     processtermination: @escaping ([String]?, Int?) -> Void)
    {
        self.init(arguments: arguments,
                  config: nil,
                  processtermination: processtermination)
    }

    deinit {
        self.monitor?.stopMonitoring()
        self.monitor = nil
        SharedReference.shared.process = nil
        Logger.process.info("RsyncProcessNOFilehandler: DEINIT")
    }
}

extension RsyncProcessNOFilehandler {
    func propogateerror(error: Error) {
        SharedReference.shared.errorobject?.alert(error: error)
    }
}

// swiftlint:enable function_body_length cyclomatic_complexity line_length
