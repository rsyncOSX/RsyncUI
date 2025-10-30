//
//  ProcessRsyncVer3x.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 03/08/2025.
//

import Foundation
import OSLog

@MainActor
final class ProcessRsyncVer3x {
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
    // AsyncSequence
    let sequencefilehandler = NotificationCenter.default.notifications(named: NSNotification.Name.NSFileHandleDataAvailable, object: nil)
    let sequencetermination = NotificationCenter.default.notifications(named: Process.didTerminateNotification, object: nil)
    // Tasks
    var sequenceFileHandlerTask: Task<Void, Never>?
    var sequenceTerminationTask: Task<Void, Never>?
    // The real run
    // Used to not report the last status from rsync for more precise progress report
    // the not reported lines are appended to output though for logging statistics reporting
    var realrun: Bool = false
    // The beginning of summarized status is discovered
    // rsync = "Number of files" at start of last line nr 16
    // openrsync = "Number of files" at start of last line nr 14
    var beginningofsummarizedstatus: Bool = false
    // When RsyncUI starts or version of rsync is changed
    // the arguments is only one and contains ["--version"] only
    var getrsyncversion: Bool = false

    func executeProcess() {
        // Must check valid rsync exists
        guard SharedReference.shared.norsync == false else { return }
        guard config?.task != SharedReference.shared.halted else { return }
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

        sequenceFileHandlerTask = Task {
            for await _ in sequencefilehandler {
                if self.getrsyncversion == true {
                    await self.datahandlersyncversion(pipe)
                } else {
                    await self.datahandle(pipe)
                }
            }
            // Final drain - keep reading until no more data
            while pipe.fileHandleForReading.availableData.count > 0 {
                Logger.process.info("ProcessRsyncVer3x: sequenceFileHandlerTask - drain remaining data")
                if self.getrsyncversion == true {
                    await self.datahandlersyncversion(pipe)
                } else {
                    await self.datahandle(pipe)
                }
            }
        }

        sequenceTerminationTask = Task {
            for await _ in sequencetermination {
                // Small delay to let final data arrive
                try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
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
            Logger.process.info("ProcessRsyncVer3x: \(launchPath, privacy: .public)")
            Logger.process.info("ProcessRsyncVer3x: \(arguments.joined(separator: "\n"), privacy: .public)")
        }
    }

    func propogateerror(error: Error) {
        SharedReference.shared.errorobject?.alert(error: error)
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
        let argumentscontainsdryrun = arguments?.contains("--dry-run") ?? false
        realrun = !argumentscontainsdryrun

        if arguments?.count == 1 {
            getrsyncversion = arguments?.contains("--version") ?? false
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
                     config: SynchronizeConfiguration?,
                     processtermination: @escaping ([String]?, Int?) -> Void)
    {
        // To satisfy arguments
        let filehandler: (Int) -> Void = { _ in
            Logger.process.info("ProcessRsyncVer3x: You should NOT SEE this message")
        }
        self.init(arguments: arguments,
                  config: config,
                  processtermination: processtermination,
                  filehandler: filehandler,
                  usefilehandler: false)
    }

    convenience init(arguments: [String]?,
                     processtermination: @escaping ([String]?, Int?) -> Void)
    {
        // To satisfy arguments
        let filehandler: (Int) -> Void = { _ in
            Logger.process.info("ProcessRsyncVer3x: You should not SEE this message")
        }
        self.init(arguments: arguments,
                  config: nil,
                  processtermination: processtermination,
                  filehandler: filehandler,
                  usefilehandler: false)
    }

    deinit {
        Logger.process.info("ProcessRsyncVer3x: DEINIT")
    }
}

extension ProcessRsyncVer3x {
    func datahandlersyncversion(_ pipe: Pipe) async {
        let outHandle = pipe.fileHandleForReading
        let data = outHandle.availableData
        if data.count > 0 {
            if let str = NSString(data: data, encoding: String.Encoding.utf8.rawValue) {
                str.enumerateLines { line, _ in
                    self.output.append(line)
                }
                outHandle.waitForDataInBackgroundAndNotify()
            }
        }
    }

    func datahandle(_ pipe: Pipe) async {
        let outHandle = pipe.fileHandleForReading
        let data = outHandle.availableData
        if data.count > 0 {
            if let str = NSString(data: data, encoding: String.Encoding.utf8.rawValue) {
                str.enumerateLines { line, _ in
                    self.output.append(line)
                    // realrun == true if arguments does not contain --dry-run parameter
                    if self.realrun, self.beginningofsummarizedstatus == false {
                        if line.contains("Number of files") {
                            self.beginningofsummarizedstatus = true
                            Logger.process.info("ProcessRsyncVer3x: datahandle() beginning of status reports discovered")
                        }
                    }
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
                // Send message about files, do not report the last lines of status from rsync if
                // the real run is ongoing
                if usefilehandler, beginningofsummarizedstatus == false, realrun == true {
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
            Task {
                await ActorLogToFile(command: config.backupID,
                                     stringoutputfromrsync: output)
            }
        }
        SharedReference.shared.process = nil
        // Remove observers
        NotificationCenter.default.removeObserver(sequencefilehandler as Any,
                                                  name: NSNotification.Name.NSFileHandleDataAvailable,
                                                  object: nil)
        NotificationCenter.default.removeObserver(sequencetermination as Any,
                                                  name: Process.didTerminateNotification,
                                                  object: nil)
        // Cancel Tasks
        sequenceFileHandlerTask?.cancel()
        sequenceTerminationTask?.cancel()

        Logger.process.info("ProcessRsyncVer3x: process = nil and termination discovered \(Thread.isMain, privacy: .public) but on \(Thread.current, privacy: .public)")
    }
}
