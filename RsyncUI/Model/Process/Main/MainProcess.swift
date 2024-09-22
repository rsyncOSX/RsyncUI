//
//  MainProcess.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 15/03/2021.
//
// swiftlint:disable function_body_length cyclomatic_complexity line_length

import Combine
import Foundation
import OSLog

@MainActor
final class MainProcess: PropogateError {
    // Combine subscribers
    var subscriptons = Set<AnyCancellable>()
    var config: SynchronizeConfiguration?
    // Command to be executed, normally rsync
    var command: String?
    // Arguments to command
    var arguments: [String]?
    // Process termination
    var processtermination: (([String]?, Int?) -> Void)?
    // Process termination NO hiddenID
    var processtermination_noInt: (([String]?) -> Void)?
    // Reporting files
    var filehandler: ((Int) -> Void)?
    // Output
    var outputprocess: OutputfromProcess?

    func executeProcess() {
        // Must check valid rsync exists
        guard SharedReference.shared.norsync == false else { return }
        // Process
        let task = Process()
        // Either set the command or rsync
        if let command {
            task.launchPath = command
        } else {
            task.launchPath = GetfullpathforRsync().rsyncpath()
        }

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
        // Combine, subscribe to NSNotification.Name.NSFileHandleDataAvailable
        NotificationCenter.default.publisher(
            for: NSNotification.Name.NSFileHandleDataAvailable)
            .sink { _ in
                let data = outHandle.availableData
                if data.count > 0 {
                    if let str = NSString(data: data, encoding: String.Encoding.utf8.rawValue) {
                        self.outputprocess?.addlinefromoutput(str: str as String)

                        // RsyncProcessFilehandler
                        if let filehandler = self.filehandler {
                            // Send message about files
                            filehandler(self.outputprocess?.getOutput()?.count ?? 0)
                        }
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
                if let config = self.config, let processtermination = self.processtermination {
                    processtermination(self.outputprocess?.getOutput(), config.hiddenID)
                } else if let processtermination = self.processtermination {
                    processtermination(self.outputprocess?.getOutput(), -1)
                } else if let processtermination_noInt = self.processtermination_noInt {
                    processtermination_noInt(self.outputprocess?.getOutput())
                }

                // Logg to file
                if self.arguments?.contains("--dry-run") == false,
                   self.arguments?.contains("--version") == false,
                   let config = self.config
                {
                    if SharedReference.shared.logtofile {
                        Logfile(command: config.backupID, data: TrimOutputFromRsync(self.outputprocess?.getOutput() ?? []).trimmeddata)
                    }
                }
                SharedReference.shared.process = nil
                Logger.process.info("MainProcess: process = nil and termination discovered")
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
            Logger.process.info("MainProcess: \(launchPath, privacy: .public)")
            Logger.process.info("MainProcess: \(arguments.joined(separator: "\n"), privacy: .public)")
        }
        if SharedReference.shared.monitornetworkconnection {
            Task {
                var sshport = 22
                if let port = config?.sshport, port != -1 {
                    sshport = port
                } else if let port = SharedReference.shared.sshport, port != -1 {
                    sshport = port
                }
                do {
                    if let server = config?.offsiteServer, server.isEmpty == false {
                        Logger.process.info("MainProcess checking networkconnection server: \(server, privacy: .public) port: \(sshport, privacy: .public)")
                        _ = try await TCPconnections().asyncverifyTCPconnection(config?.offsiteServer ?? "", port: sshport)
                    }

                } catch let e {
                    let error = e
                    propogateerror(error: error)
                }
            }
        }
    }

    init(command: String?,
         arguments: [String]?,
         config: SynchronizeConfiguration?,
         processtermination: (([String]?, Int?) -> Void)?,
         processtermination_noInt _: (([String]?) -> Void)?,
         filehandler _: ((Int) -> Void)?)
    {
        self.command = command
        self.arguments = arguments
        self.processtermination = processtermination

        outputprocess = OutputfromProcess()
        if let config {
            self.config = config
        }
    }

    // RsyncProcessFilehandler
    convenience init(
        arguments: [String]?,
        config: SynchronizeConfiguration?,
        processtermination: @escaping ([String]?, Int?) -> Void,
        filehandler: @escaping (Int) -> Void
    ) {
        self.init(command: nil,
                  arguments: arguments,
                  config: config,
                  processtermination: processtermination,
                  processtermination_noInt: nil,
                  filehandler: filehandler)
    }

    // RsyncProcessNOFilehandler
    convenience init(
        arguments: [String]?,
        config: SynchronizeConfiguration?,
        processtermination: @escaping ([String]?, Int?) -> Void
    ) {
        self.init(command: nil,
                  arguments: arguments,
                  config: config,
                  processtermination: processtermination,
                  processtermination_noInt: nil,
                  filehandler: nil)
    }

    // CommandProcess
    convenience init(command: String?,
                     arguments: [String]?,
                     processtermination_noInt: @escaping ([String]?) -> Void)
    {
        self.init(command: command,
                  arguments: arguments,
                  config: nil,
                  processtermination: nil,
                  processtermination_noInt: processtermination_noInt,
                  filehandler: nil)
    }
    
    // CommandProcess
    convenience init(arguments: [String]?,
                     processtermination_noInt: @escaping ([String]?) -> Void)
    {
        self.init(command: nil,
                  arguments: arguments,
                  config: nil,
                  processtermination: nil,
                  processtermination_noInt: processtermination_noInt,
                  filehandler: nil)
    }

    deinit {
        Logger.process.info("MainProcess: DEINIT")
    }
}

// swiftlint:enable function_body_length cyclomatic_complexity line_length
