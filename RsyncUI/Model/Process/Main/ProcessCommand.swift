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
    
    // Tasks
    var sequenceFileHandlerTask: Task<Void, Never>?
    var waitForExitTask: Task<Void, Never>?

    // Keep references so termination can drain remaining data reliably
    private var pipe: Pipe?
    private var outHandle: FileHandle?
    // Ensure termination is handled only once (guard against both terminationHandler and waitUntilExit firing)
    private var terminationHandled: Bool = false
    
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
                propogateerror(error: error)
            }
            if let launchPath = task.launchPath, let arguments = task.arguments {
                Logger.process.info("ProcessCommand: \(launchPath, privacy: .public)")
                Logger.process.info("ProcessCommand: \(arguments.joined(separator: "\n"), privacy: .public)")
            }
        } else {
            Logger.process.warning("ProcessCommand: no command to executed or arguments = 0")
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
        // Cancel file handler task (this will also cause the NotificationCenter sequence to be released)
        sequenceFileHandlerTask?.cancel()
        waitForExitTask?.cancel()

        Logger.process.info("ProcessCommand: process = nil and termination discovered \(Thread.isMain, privacy: .public) but on \(Thread.current, privacy: .public)")
    }
}
