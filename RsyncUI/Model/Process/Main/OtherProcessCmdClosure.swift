//
//  OtherProcessCmdClosure.swift
//  RsyncOSX
//
//  Created by Thomas Evensen on 17/09/2020.
//  Copyright © 2020 Thomas Evensen. All rights reserved.
//
//  swiftlint:disable line_length opening_brace

import Foundation

class OtherProcessCmdClosure: Delay {
    // Process termination and filehandler closures
    var processtermination: () -> Void
    var filehandler: () -> Void
    // Observers
    var notifications_datahandle: NSObjectProtocol?
    var notifications_termination: NSObjectProtocol?
    // Command to be executed, normally rsync
    var command: String?
    // Arguments to command
    var arguments: [String]?
    // true if processtermination
    var termination: Bool = false

    func executeProcess(outputprocess: OutputProcess?) {
        guard command != nil else { return }
        // Process
        let task = Process()
        // If self.command != nil either alternativ path for rsync or other command than rsync to be executed
        if let command = self.command {
            task.launchPath = command
        }
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
                self.termination = true
                self.processtermination()
                // Must remove for deallocation
                NotificationCenter.default.removeObserver(self.notifications_datahandle as Any)
                NotificationCenter.default.removeObserver(self.notifications_termination as Any)
                // Enable select profile
                // self.profilepopupDelegate?.enableselectpopupprofile()
                self.notifications_datahandle = nil
                self.notifications_termination = nil
                // Logg to file
                _ = Logfile(outputprocess)
            }
        }
        SharedReference.shared.process = task
        // self.profilepopupDelegate?.disableselectpopupprofile()
        do {
            try task.run()
        } catch let e {
            let error = e
            self.propogateerror(error: error)
        }
    }

    init(command: String?,
         arguments: [String]?,
         processtermination: @escaping () -> Void,
         filehandler: @escaping () -> Void)
    {
        self.command = command
        self.arguments = arguments
        self.processtermination = processtermination
        self.filehandler = filehandler
    }

    deinit {
        SharedReference.shared.process = nil
    }
}

extension OtherProcessCmdClosure: PropogateError {
    func propogateerror(error: Error) {
        SharedReference.shared.errorobject?.propogateerror(error: error)
    }
}
