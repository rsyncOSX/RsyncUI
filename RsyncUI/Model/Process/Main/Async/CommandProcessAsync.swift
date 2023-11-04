//
//  CommandProcessAsync.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 28/10/2022.
//

import Combine
import Foundation
import OSLog

@MainActor
final class CommandProcessAsync {
    // Combine subscribers
    var subscriptons = Set<AnyCancellable>()
    // Command to be executed, normally rsync
    var command: String?
    // Arguments to command
    var arguments: [String]?
    // Process termination closure
    var processtermination: ([String]?) -> Void
    // Output
    var outputprocess: OutputfromProcess?

    func executeProcess() async {
        guard command != nil else { return }
        // Process
        // Process
        let task = Process()
        // If self.command != nil either alternativ path for rsync or other command than rsync to be executed
        if let command = command {
            task.launchPath = command
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
                // Logg to file
                self.processtermination(self.outputprocess?.getOutput())
                // Release Combine subscribers
                // print("process termination")
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
            Logger.process.info("CommandProcessAsync: \(launchPath, privacy: .public)")
            Logger.process.info("CommandProcessAsync: \(arguments, privacy: .public)")
        }
    }

    // Terminate Process, used when user Aborts task.
    func abortProcess() {
        _ = InterruptProcess()
    }

    init(command: String?,
         arguments: [String]?,
         processtermination: @escaping ([String]?) -> Void)
    {
        self.command = command
        self.arguments = arguments
        self.processtermination = processtermination
        outputprocess = OutputfromProcess()
    }

    deinit {
        SharedReference.shared.process = nil
        // print("deinit RsyncAsync")
    }
}

extension CommandProcessAsync {
    func propogateerror(error: Error) {
        SharedReference.shared.errorobject?.alert(error: error)
    }
}
