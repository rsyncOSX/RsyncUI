//
//  RsyncProcessCmdCombine.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 15/03/2021.
//

import Combine
import Foundation

final class RsyncProcess {
    // Combine subscribers
    var subscriptons = Set<AnyCancellable>()
    // Process termination and filehandler closures
    var processtermination: () -> Void
    var filehandler: () -> Void
    // Verify network connection
    var config: Configuration?
    var monitor: NetworkMonitor?
    // Arguments to command
    var arguments: [String]?

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
            let output = OutputfromProcess()
            let string = NSLocalizedString("Network connection is dropped", comment: "network") + ":"
                + Date().long_localized_string_from_date()
            output.addlinefromoutput(str: string)
            _ = InterruptProcess(output: output)
            throw Networkerror.networkdropped
        }
    }

    func executeProcess(outputprocess: OutputfromProcess?) {
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
                        outputprocess?.addlinefromoutput(str: str as String)
                        // Send message about files
                        self.filehandler()
                    }
                    outHandle.waitForDataInBackgroundAndNotify()
                }
            }.store(in: &subscriptons)
        // Combine, subscribe to Process.didTerminateNotification
        NotificationCenter.default.publisher(
            for: Process.didTerminateNotification)
            .debounce(for: .milliseconds(500), scheduler: globalMainQueue)
            .sink { [self] _ in
                self.processtermination()
                // Logg to file
                _ = Logfile(outputprocess)
                // Release Combine subscribers
                subscriptons.removeAll()
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
         processtermination: @escaping () -> Void,
         filehandler: @escaping () -> Void)
    {
        self.arguments = arguments
        self.processtermination = processtermination
        self.filehandler = filehandler
        self.config = config
        executemonitornetworkconnection()
    }

    deinit {
        self.monitor?.stopMonitoring()
        self.monitor = nil
        SharedReference.shared.process = nil
        // print("deinit RsyncProcessCmdCombine")
    }
}

extension RsyncProcess: PropogateError {
    func propogateerror(error: Error) {
        SharedReference.shared.errorobject?.propogateerror(error: error)
    }
}
