//
//  RsyncProcessCmdClosure.swift
//  RsyncOSX
//
//  Created by Thomas Evensen on 14/09/2020.
//  Copyright © 2020 Thomas Evensen. All rights reserved.
//
//  swiftlint:disable line_length opening_brace
//
//
// NOT USED - SEE RsyncProcessCmdCombineClosure

import Foundation

class RsyncProcessCmdClosure: Delay {
    // Process termination and filehandler closures
    var processtermination: () -> Void
    var filehandler: () -> Void
    // Verify network connection
    var config: Configuration?
    var monitor: NetworkMonitor?
    // Observers
    var notifications_datahandle: NSObjectProtocol?
    var notifications_termination: NSObjectProtocol?
    // Arguments to command
    var arguments: [String]?
    // true if processtermination
    var termination: Bool = false

    func executemonitornetworkconnection() {
        guard config?.offsiteServer.isEmpty == false else { return }
        guard SharedReference.shared.monitornetworkconnection == true else { return }
        monitor = NetworkMonitor()
        monitor?.netStatusChangeHandler = { [unowned self] in
            do {
                try statusDidChange()
            } catch let e {
                let error = e
                self.propogateerror(error: error)
            }
        }
    }

    // Throws error
    func statusDidChange() throws {
        if monitor?.monitor?.currentPath.status != .satisfied {
            let output = OutputProcess()
            let string = "Network connection is dropped: " + Date().long_localized_string_from_date()
            output.addlinefromoutput(str: string)
            _ = InterruptProcess(output: output)
            throw Networkerror.networkdropped
        }
    }

    func executeProcess(outputprocess: OutputProcess?) {
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
        // Observator for reading data from pipe, observer is removed when Process terminates
        notifications_datahandle = NotificationCenter.default.addObserver(forName: NSNotification.Name.NSFileHandleDataAvailable, object: nil, queue: nil) { [weak self] _ in
            let data = outHandle.availableData
            if data.count > 0 {
                if let str = NSString(data: data, encoding: String.Encoding.utf8.rawValue) {
                    outputprocess?.addlinefromoutput(str: str as String)
                    // Send message about files
                    self?.filehandler()
                }
                outHandle.waitForDataInBackgroundAndNotify()
            }
        }
        // Observator Process termination, observer is removed when Process terminates
        notifications_termination = NotificationCenter.default.addObserver(forName: Process.didTerminateNotification, object: nil, queue: nil) { _ in
            self.delayWithSeconds(0.5) {
                if self.termination == false {
                    self.processtermination()
                }
                self.termination = true
                // Must remove for deallocation
                NotificationCenter.default.removeObserver(self.notifications_datahandle as Any)
                NotificationCenter.default.removeObserver(self.notifications_termination as Any)
                self.notifications_datahandle = nil
                self.notifications_termination = nil
                // Logg to file
                _ = Logfile(outputprocess)
            }
        }
        SharedReference.shared.process = task
        do {
            try task.run()
        } catch let e {
            let error = e
            self.propogateerror(error: error)
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
        // print("deinit RsyncProcessCmdClosure")
    }
}

extension RsyncProcessCmdClosure: PropogateError {
    func propogateerror(error: Error) {
        SharedReference.shared.errorobject?.propogateerror(error: error)
    }
}
