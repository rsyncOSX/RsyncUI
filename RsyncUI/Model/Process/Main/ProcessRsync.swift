//
//  ProcessRsync.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 15/03/2021.
//
// swiftlint:disable function_body_length cyclomatic_complexity line_length

// import Combine
import Foundation
import OSLog

@MainActor
final class ProcessRsync: PropogateError {
    // Combine subscribers
    // var subscriptons = Set<AnyCancellable>()
    // Process termination and filehandler closures
    var processtermination: ([String]?, Int?) -> Void
    var filehandler: (Int) -> Void
    var config: SynchronizeConfiguration?
    // Arguments to command
    var arguments: [String]?
    // Output
    var output = [String]()
    // Use filehandler
    var usefilehandler: Bool = false
    // Check for error
    var checklineforerror: TrimOutputFromRsync?
    var errordiscovered: Bool = false
    // Observer
    weak var notifications: NSObjectProtocol?

    func executeProcess() {
        // Must check valid rsync exists
        guard SharedReference.shared.norsync == false else { return }
        // Process
        let task = Process()
        // Getting version of rsync
        task.launchPath = GetfullpathforRsync().rsyncpath()
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

        notifications = NotificationCenter.default.addObserver(forName: NSNotification.Name.NSFileHandleDataAvailable,
                                                               object: nil, queue: nil)
        { _ in
            Task {
                await self.datahandle(pipe)
            }
        }

        notifications = NotificationCenter.default.addObserver(forName: Process.didTerminateNotification, object: task, queue: nil) { _ in
            Task {
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
            Logger.process.info("ProcessRsync: \(launchPath, privacy: .public)")
            Logger.process.info("ProcessRsync: \(arguments.joined(separator: "\n"), privacy: .public)")
        }
    }

    init(arguments: [String]?,
         config: SynchronizeConfiguration?,
         processtermination: @escaping ([String]?, Int?) -> Void,
         filehandler: @escaping (Int) -> Void,
         usefilehandler: Bool)
    {
        self.arguments = arguments
        self.processtermination = processtermination
        self.filehandler = filehandler
        self.usefilehandler = usefilehandler

        if let config {
            self.config = config
        }
        if SharedReference.shared.checkforerrorinrsyncoutput {
            checklineforerror = TrimOutputFromRsync()
        }
    }

    convenience init(arguments: [String]?,
                     config: SynchronizeConfiguration?,
                     processtermination: @escaping ([String]?, Int?) -> Void,
                     filehandler: @escaping (Int) -> Void)
    {
        self.init(arguments: arguments,
                  config: config,
                  processtermination: processtermination,
                  filehandler: filehandler,
                  usefilehandler: true)
    }

    convenience init(arguments: [String]?,
                     processtermination: @escaping ([String]?, Int?) -> Void)
    {
        // To satisfy arguments
        let filehandler: (Int) -> Void = { _ in
            Logger.process.info("ProcessRsync: You should not SEE this message")
        }
        self.init(arguments: arguments,
                  config: nil,
                  processtermination: processtermination,
                  filehandler: filehandler,
                  usefilehandler: false)
    }

    convenience init(arguments: [String]?,
                     config: SynchronizeConfiguration?,
                     processtermination: @escaping ([String]?, Int?) -> Void)
    {
        // To satisfy arguments
        let filehandler: (Int) -> Void = { _ in
            Logger.process.info("ProcessRsync: You should NOT SEE this message")
        }
        self.init(arguments: arguments,
                  config: config,
                  processtermination: processtermination,
                  filehandler: filehandler,
                  usefilehandler: false)
    }

    deinit {
        Logger.process.info("ProcessRsync: DEINIT")
    }
}

extension ProcessRsync {
    func datahandle(_ pipe: Pipe) async {
        let outHandle = pipe.fileHandleForReading
        let data = outHandle.availableData
        if data.count > 0 {
            if let str = NSString(data: data, encoding: String.Encoding.utf8.rawValue) {
                str.enumerateLines { line, _ in
                    self.output.append(line)
                    if SharedReference.shared.checkforerrorinrsyncoutput,
                       self.errordiscovered == false
                    {
                        do {
                            try self.checklineforerror?.checkforrsyncerror(line)
                        } catch let e {
                            self.errordiscovered = true
                            let error = e
                            self.propogateerror(error: error)
                        }
                    }
                }
                // Send message about files
                if usefilehandler {
                    filehandler(output.count)
                }
            }
            outHandle.waitForDataInBackgroundAndNotify()
        }
    }

    func termination() async {
        processtermination(output, config?.hiddenID)
        // Log error in rsync output to file
        if errordiscovered, let config {
            Logfile(command: config.backupID,
                    stringoutputfromrsync: output)
        }
        SharedReference.shared.process = nil
        NotificationCenter.default.removeObserver(notifications as Any)
        Logger.process.info("ProcessRsync: process = nil and termination discovered")
    }
}

// swiftlint:enable function_body_length cyclomatic_complexity line_length

/*
 // Combine, subscribe to NSNotification.Name.NSFileHandleDataAvailable
 NotificationCenter.default.publisher(
     for: NSNotification.Name.NSFileHandleDataAvailable)
     .sink { [self] _ in
         let data = outHandle.availableData
         if data.count > 0 {
             if let str = NSString(data: data, encoding: String.Encoding.utf8.rawValue) {
                 str.enumerateLines { line, _ in
                     self.output.append(line)
                     if SharedReference.shared.checkforerrorinrsyncoutput,
                        self.errordiscovered == false
                     {
                         do {
                             try self.checklineforerror?.checkforrsyncerror(line)
                         } catch let e {
                             self.errordiscovered = true
                             let error = e
                             self.propogateerror(error: error)
                         }
                     }
                 }
                 // Send message about files
                 if usefilehandler {
                     filehandler(output.count)
                 }
             }
             outHandle.waitForDataInBackgroundAndNotify()
         }
     }.store(in: &subscriptons)
 // Combine, subscribe to Process.didTerminateNotification
 NotificationCenter.default.publisher(
     for: Process.didTerminateNotification)
     .debounce(for: .milliseconds(500), scheduler: DispatchQueue.main)
     .sink { [self] _ in
         processtermination(output, config?.hiddenID)
         // Log error in rsync output to file
         if errordiscovered, let config {
             Logfile(command: config.backupID,
                     stringoutputfromrsync: output)
         }
         SharedReference.shared.process = nil
         Logger.process.info("ProcessRsync: process = nil and termination discovered")
         // Release Combine subscribers
         subscriptons.removeAll()
     }.store(in: &subscriptons)

  */

/*
 import Foundation

 class NewProcessRsync {

     // Number of calculated files to be copied
     var calculatedNumberOfFiles: Int = 0
     // Variable for reference to Process
     var processReference: Process?
     // Message to calling class
     weak var updateDelegate: UpdateProgress?
     // Observer
     weak var notifications: NSObjectProtocol?
     // Command to be executed, normally rsync
     var command: String?
     // Arguments to command
     var arguments: [String]?
     // true if processtermination
     var termination: Bool = false
     // possible error ouput
     weak var possibleerrorDelegate: ErrorOutput?

     func executeProcess (outputprocess: OutputProcess?) {
         // Process
         let task = Process()
         // If self.command != nil either alternativ path for rsync or other command than rsync to be executed
         if let command = self.command {
             task.launchPath = command
         } else {
             task.launchPath = Verifyrsyncpath().rsyncpath()
         }
         task.arguments = self.arguments
         // Pipe for reading output from Process
         let pipe = Pipe()
         task.standardOutput = pipe
         task.standardError = pipe
         let outHandle = pipe.fileHandleForReading
         outHandle.waitForDataInBackgroundAndNotify()
         // Observator for reading data from pipe, observer is removed when Process terminates
         self.notifications = NotificationCenter.default.addObserver(forName: NSNotification.Name.NSFileHandleDataAvailable,
                             object: nil, queue: nil) { _ in
             let data = outHandle.availableData
             if data.count > 0 {
                 if let str = NSString(data: data, encoding: String.Encoding.utf8.rawValue) {
                     if outputprocess != nil {
                         outputprocess!.addlinefromoutput(str as String)
                         self.calculatedNumberOfFiles = outputprocess!.count()
                         // Send message about files
                         self.updateDelegate?.fileHandler()
                         if self.termination {
                             self.possibleerrorDelegate?.erroroutput()
                         }
                     }
                 }
                 outHandle.waitForDataInBackgroundAndNotify()
             }
         }
         // Observator Process termination, observer is removed when Process terminates
         self.notifications = NotificationCenter.default.addObserver(forName: Process.didTerminateNotification,
                                                                     object: task, queue: nil) { _ in
             self.delayWithSeconds(0.5) {
                 self.termination = true
                 self.updateDelegate?.processTermination()
             }
             NotificationCenter.default.removeObserver(self.notifications as Any)
         }
         self.processReference = task
         task.launch()
     }

     // Get the reference to the Process object.
     func getProcess() -> Process? {
         return self.processReference
     }

     // Terminate Process, used when user Aborts task.
     func abortProcess() {
         guard self.processReference != nil else { return }
         self.processReference!.terminate()
     }

     init(command: String?, arguments: [String]?) {
         self.command = command
         self.arguments = arguments
     }
 }
 */
