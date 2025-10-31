//
//  ProcessCommand.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 03/08/2025.
//

import Foundation
import OSLog

@MainActor
final class ProcessCommand {
    // Process termination and filehandler closures
    var processtermination: ([String]?) -> Void
    // Output
    var output = [String]()
    // Command to be executed, normally rsync
    var command: String?
    // Arguments to command
    var arguments: [String]?
    // Task handlers
    var sequenceFileHandlerTask: Task<Void, Never>?
    var sequenceTerminationTask: Task<Void, Never>?

    
    func executeProcess() {
        if let command, let arguments, arguments.count > 0 {
            let task = Process()
            task.launchPath = command
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

            // AsyncSequence
            let sequencefilehandler = NotificationCenter.default.notifications(
                named: NSNotification.Name.NSFileHandleDataAvailable,
                object: outHandle)
            let sequencetermination = NotificationCenter.default.notifications(
                named: Process.didTerminateNotification,
                object: task)

            sequenceFileHandlerTask = Task {
                for await _ in sequencefilehandler {
                    await self.datahandle(pipe)
                }
            }

            sequenceTerminationTask = Task {
                for await _ in sequencetermination {
                    Logger.process.info("ProcessRsyncVer3x: Process terminated - starting potensial drain")
                    sequenceFileHandlerTask?.cancel()
                    try? await Task.sleep(nanoseconds: 50_000_000)
                    var totalDrained = 0
                    while true {
                        let data: Data = pipe.fileHandleForReading.availableData
                        if data.isEmpty {
                            Logger.process.info("ProcessRsyncVer3x: Drain complete - \(totalDrained) bytes total")
                            break
                        }

                        totalDrained += data.count
                        Logger.process.info("ProcessRsyncVer3x: Draining \(data.count) bytes")

                        // IMPORTANT: Actually process the drained data
                        if let text = String(data: data, encoding: .utf8) {
                            Logger.process.info("ProcessRsyncVer3x: Drained text: \(text)")
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
                Logger.process.info("ProcessCommand: command - \(launchPath, privacy: .public)")
                Logger.process.info("ProcessCommand: arguments - \(arguments.joined(separator: "\n"), privacy: .public)")
            }
        }
    }

    func propogateerror(error: Error) {
        SharedReference.shared.errorobject?.alert(error: error)
    }

    init(command: String?,
         arguments: [String]?,
         processtermination: @escaping ([String]?) -> Void)
    {
        self.command = command
        self.arguments = arguments
        self.processtermination = processtermination
    }

    convenience init(command: String?,
                     arguments: [String]?)
    {
        let processtermination: ([String]?) -> Void = { _ in
            Logger.process.info("ProcessCommand: You SEE this message only when Process() is terminated")
        }
        self.init(command: command,
                  arguments: arguments,
                  processtermination: processtermination)
    }

    deinit {
        Logger.process.info("ProcessCommand: DEINIT")
    }
}

extension ProcessCommand {
    func datahandle(_ pipe: Pipe) async {
        let outHandle = pipe.fileHandleForReading
        let data = outHandle.availableData
        if data.count > 0 {
            if let str = NSString(data: data, encoding: String.Encoding.utf8.rawValue) {
                str.enumerateLines { line, _ in
                    self.output.append(line)
                }
            }
            outHandle.waitForDataInBackgroundAndNotify()
        }
    }

    func termination() async {
        processtermination(output)

        SharedReference.shared.process = nil
        sequenceFileHandlerTask?.cancel()
        sequenceTerminationTask?.cancel()

        Logger.process.info("ProcessCommand: process = nil and termination discovered \(Thread.isMain, privacy: .public) but on \(Thread.current, privacy: .public)")
    }
}
