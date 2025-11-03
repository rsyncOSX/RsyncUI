//
//  ProcessRsyncVer3x.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 03/11/2025.
//

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
    // Process handlers
    let handlers: ProcessHandlers
    // Arguments to command
    var arguments: [String]?
    // Output
    var output = [String]()
    // Use filehandler
    var usefilehandler: Bool = false
    // Check for error
    var errordiscovered: Bool = false
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
    // hiddenID
    var hiddenID: Int = -1

    func executeProcess() {
        // Process
        let task = Process()
        // Getting version of rsync
        task.launchPath = handlers.rsyncpath()
        guard task.launchPath != nil else { return }
        task.arguments = arguments
        // If there are any Environmentvariables like
        // SSH_AUTH_SOCK": "/Users/user/.gnupg/S.gpg-agent.ssh"
        // MUST FIX
        /*
         if let environment = MyEnvironment() {
             task.environment = environment.environment
         }
          */
        // Pipe for reading output from Process
        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = pipe
        let outHandle = pipe.fileHandleForReading
        outHandle.waitForDataInBackgroundAndNotify()

        // AsyncSequence
        let sequencefilehandler = NotificationCenter.default.notifications(
            named: NSNotification.Name.NSFileHandleDataAvailable,
            object: outHandle
        )
        let sequencetermination = NotificationCenter.default.notifications(
            named: Process.didTerminateNotification,
            object: task
        )

        sequenceFileHandlerTask = Task {
            for await _ in sequencefilehandler {
                if self.getrsyncversion == true {
                    await self.datahandlersyncversion(pipe)
                } else {
                    await self.datahandle(pipe)
                }
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
                        // Logger.process.info("ProcessRsyncVer3x: Drained text: \(text)")
                        self.output.append(text)
                    }
                }

                await self.termination()
            }
        }
        // Update current process task
        handlers.updateprocess(task)

        do {
            try task.run()
        } catch let e {
            let error = e
            SharedReference.shared.errorobject?.alert(error: error)
        }
        if let launchPath = task.launchPath, let arguments = task.arguments {
            Logger.process.info("ProcessRsyncVer3x: command - \(launchPath, privacy: .public)")
            Logger.process.info("ProcessRsyncVer3x: arguments - \(arguments.joined(separator: "\n"), privacy: .public)")
        }
    }

    init(arguments: [String]?,
         hiddenID: Int,
         handlers: ProcessHandlers,
         usefilehandler: Bool)
    {
        self.arguments = arguments
        self.hiddenID = hiddenID
        self.handlers = handlers
        self.usefilehandler = usefilehandler

        let argumentscontainsdryrun = arguments?.contains("--dry-run") ?? false
        realrun = !argumentscontainsdryrun

        if arguments?.count == 1 {
            getrsyncversion = arguments?.contains("--version") ?? false
        }
    }

    convenience init(arguments: [String]?,
                     handlers: ProcessHandlers,
                     filhandler: Bool)
    {
        self.init(arguments: arguments,
                  hiddenID: -1,
                  handlers: handlers,
                  usefilehandler: filhandler)
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
                    if self.handlers.checkforerrorinrsyncoutput,
                       self.errordiscovered == false
                    {
                        do {
                            try self.handlers.checklineforerror(line)
                        } catch let e {
                            self.errordiscovered = true
                            let error = e
                            self.handlers.propogateerror(error)
                        }
                    }
                }
                // Send message about files, do not report the last lines of status from rsync if
                // the real run is ongoing
                if usefilehandler, beginningofsummarizedstatus == false, realrun == true {
                    handlers.filehandler(output.count)
                }
            }
            outHandle.waitForDataInBackgroundAndNotify()
        }
    }

    func termination() async {
        handlers.processtermination(output, hiddenID)
        // Log error in rsync output to file
        /*
         if errordiscovered, let config {
             Task {
                 await ActorLogToFile(command: config.backupID,
                                      stringoutputfromrsync: output)
             }
         }
          */
        // Set current process to nil
        handlers.updateprocess(nil)
        // Cancel Tasks
        sequenceFileHandlerTask?.cancel()
        sequenceTerminationTask?.cancel()

        Logger.process.info("ProcessRsyncVer3x: process = nil and termination discovered \(Thread.isMain, privacy: .public) but on \(Thread.current, privacy: .public)")
    }
}
