//
//  RsyncProcessAsync.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 15/03/2021.
//

import Combine
import Foundation

@MainActor
final class RsyncProcessAsync {
    // Combine subscribers
    var subscriptons = Set<AnyCancellable>()
    // Verify network connection
    var config: Configuration?
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
        if let environment = Environment() {
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
            }.store(in: &subscriptons)
        SharedReference.shared.process = task
        do {
            try task.run()
        } catch let e {
            let error = e
            propogateerror(error: error)
        }
    }

    // Terminate Process, used when user Aborts task.
    func abortProcess() {
        _ = InterruptProcess()
    }

    init(arguments: [String]?,
         config: Configuration?,
         processtermination: @escaping ([String]?, Int?) -> Void)
    {
        self.arguments = arguments
        self.config = config
        self.processtermination = processtermination
        outputprocess = OutputfromProcess()
        executemonitornetworkconnection()
    }

    deinit {
        self.monitor?.stopMonitoring()
        self.monitor = nil
        SharedReference.shared.process = nil
    }
}

extension RsyncProcessAsync: PropogateError {
    func propogateerror(error: Error) {
        SharedReference.shared.errorobject?.propogateerror(error: error)
    }
}
