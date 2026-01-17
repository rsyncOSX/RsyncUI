//
//  Execute.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 10/06/2025.
//
/* swiftlint:disable cyclomatic_complexity */

import Foundation
import OSLog
import ParseRsyncOutput
import RsyncProcessStreaming

enum ErrorDatatoSynchronize: LocalizedError {
    case thereisdatatosynchronize(idwitherror: String)

    var errorDescription: String? {
        switch self {
        case let .thereisdatatosynchronize(idwitherror):
            "There are errors in tagging data\n for synchronize ID \(idwitherror)\n"
                + "Most likely number of rows\n> 20 lines and no data to synchronize"
        }
    }
}

@MainActor
final class Execute {
    private var localconfigurations: [SynchronizeConfiguration]
    private var structprofile: String?
    private var setabort = false

    weak var localprogressdetails: ProgressDetails?
    weak var localnoestprogressdetails: NoEstProgressDetails?

    // Collect loggdata for later save to permanent storage (hiddenID, log)
    private var configrecords = [ScheduleLogData]()
    private var schedulerecords = [ScheduleLogData]()
    // Report progress to caller
    var localfileHandler: (Int) -> Void
    // Update configurations
    var localupdateconfigurations: ([SynchronizeConfiguration]) -> Void
    var stackoftasks: [Int]?

    let defaultstats = "0 files : 0.00 MB in 0.00 seconds"

    // Streaming strong references
    private var streamingHandlers: RsyncProcessStreaming.ProcessHandlers?
    private var activeStreamingProcess: RsyncProcessStreaming.RsyncProcess?

    private func getConfig(_ hiddenID: Int) -> SynchronizeConfiguration? {
        if let index = localconfigurations.firstIndex(where: { $0.hiddenID == hiddenID }) {
            return localconfigurations[index]
        }
        return nil
    }

    private func startexecution() {
        guard !(stackoftasks?.isEmpty ?? true) else { return }
        streamingHandlers = CreateStreamingHandlers().createHandlers(
            fileHandler: localfileHandler,
            processTermination: { output, hiddenID in
                self.processTermination(stringoutputfromrsync: output, hiddenID)
                if SharedReference.shared.saveactualsynclogdata {
                    Task {
                        Logger.process.debugMessageOnly("Execute: LOGGING details to logfile")
                        _ = await ActorLogToFile().logOutput("rsync", output)
                    }
                }
            }
        )

        if let localhiddenID = stackoftasks?.removeFirst() {
            // For display progress of synchronization of correct task
            localprogressdetails?.hiddenIDatwork = localhiddenID
            if let config = getConfig(localhiddenID) {
                if let arguments = ArgumentsSynchronize(config: config).argumentsSynchronize(dryRun: false,
                                                                                             forDisplay: false) {
                    guard let streamingHandlers else { return }
                    let process = RsyncProcessStreaming.RsyncProcess(
                        arguments: arguments,
                        hiddenID: config.hiddenID,
                        handlers: streamingHandlers,
                        useFileHandler: true
                    )
                    // Must check valid rsync exists
                    guard SharedReference.shared.norsync == false else { return }
                    guard config.task != SharedReference.shared.halted else { return }

                    if SharedReference.shared.validatearguments {
                        do {
                            try ValidateArguments().validate(config: config, arguments: arguments)
                        } catch let err {
                            let error = err
                            SharedReference.shared.errorobject?.alert(error: error)
                        }
                    }

                    do {
                        try process.executeProcess()
                        activeStreamingProcess = process
                    } catch let err {
                        let error = err
                        SharedReference.shared.errorobject?.alert(error: error)
                    }
                }
            }
        }
    }

    private func startexecution_noestimate() {
        guard !(stackoftasks?.isEmpty ?? true) else { return }
        streamingHandlers = CreateStreamingHandlers().createHandlers(
            fileHandler: localfileHandler,
            processTermination: { output, hiddenID in
                self.processTermination_noestimation(stringoutputfromrsync: output, hiddenID)
            }
        )

        if let localhiddenID = stackoftasks?.removeFirst() {
            if let config = getConfig(localhiddenID) {
                if let arguments = ArgumentsSynchronize(config: config).argumentsSynchronize(dryRun: false,
                                                                                             forDisplay: false) {
                    // Must check valid rsync exists
                    guard SharedReference.shared.norsync == false else { return }
                    guard config.task != SharedReference.shared.halted else { return }

                    if SharedReference.shared.validatearguments {
                        do {
                            try ValidateArguments().validate(config: config, arguments: arguments)
                        } catch let err {
                            let error = err
                            SharedReference.shared.errorobject?.alert(error: error)
                        }
                    }
                    guard let streamingHandlers else { return }

                    let process = RsyncProcessStreaming.RsyncProcess(
                        arguments: arguments,
                        hiddenID: config.hiddenID,
                        handlers: streamingHandlers,
                        useFileHandler: true
                    )

                    do {
                        try process.executeProcess()
                        activeStreamingProcess = process
                    } catch let err {
                        let error = err
                        SharedReference.shared.errorobject?.alert(error: error)
                    }
                }
            }
        }
    }

    private func computestackoftasks(_ selecteduuids: Set<UUID>) -> [Int] {
        if selecteduuids.count > 0 {
            let configurations = localconfigurations.filter { selecteduuids.contains($0.id)
                && $0.task != SharedReference.shared.halted
            }
            return configurations.map(\.hiddenID)
        } else {
            // Or go for all
            let configurations = localconfigurations.filter { $0.task != SharedReference.shared.halted }
            return configurations.map(\.hiddenID)
        }
    }

    @discardableResult
    init(profile: String?,
         configurations: [SynchronizeConfiguration],
         selecteduuids: Set<UUID>,
         progressdetails: ProgressDetails?,
         fileHandler: @escaping (Int) -> Void,
         updateconfigurations: @escaping ([SynchronizeConfiguration]) -> Void) {
        structprofile = profile
        localconfigurations = configurations
        localprogressdetails = progressdetails
        localfileHandler = fileHandler
        localupdateconfigurations = updateconfigurations

        guard selecteduuids.count > 0 else { return }
        let taskstosynchronize = localconfigurations.filter {
            selecteduuids.contains($0.id) && $0.task != SharedReference.shared.halted
        }
        stackoftasks = taskstosynchronize.map(\.hiddenID)
        guard !(stackoftasks?.isEmpty ?? true) else { return }
        Logger.process.debugMessageOnly("Execute: START EXECUTION")
        startexecution()
    }

    @discardableResult
    init(profile: String?,
         configurations: [SynchronizeConfiguration],
         selecteduuids: Set<UUID>,
         noestprogressdetails: NoEstProgressDetails?,
         fileHandler: @escaping (Int) -> Void,
         updateconfigurations: @escaping ([SynchronizeConfiguration]) -> Void) {
        structprofile = profile
        localconfigurations = configurations
        localnoestprogressdetails = noestprogressdetails
        localfileHandler = fileHandler
        localupdateconfigurations = updateconfigurations

        stackoftasks = computestackoftasks(selecteduuids)
        startexecution_noestimate()
    }

    deinit {
        Logger.process.debugMessageOnly("Execute: DEINIT")
        self.stackoftasks = nil
    }
}

extension Execute {
    private func processTermination(stringoutputfromrsync: [String]?, _ hiddenID: Int?) {
        guard setabort == false else { return }
        guard let hiddenID else { return }

        // Log records
        // If snahost task the snapshotnum is increased when updating the configuration.
        // When creating the logrecord, decrease the snapshotum by 1
        let element = ScheduleLogData(hiddenID: hiddenID, stats: Date().en_string_from_date())
        configrecords.append(element)
        // Prepareoutput prepares output from rsync for extracting the numbers only.
        // It removes all lines except the last 20 lines where summarized numbers are put
        let preparedoutputfromrsync = PrepareOutputFromRsync().prepareOutputFromRsync(stringoutputfromrsync)

        if SharedReference.shared.addsummarylogrecord {
            do {
                let stats = try ParseRsyncOutput(preparedoutputfromrsync,
                                                 SharedReference.shared.rsyncversion3 ? .ver3 : .openrsync).getstats()
                let logData = ScheduleLogData(hiddenID: hiddenID, stats: stats ?? defaultstats)
                schedulerecords.append(logData)
                Logger.process.debugMessageOnly("Execute: getstats() SUCCESS")
            } catch let err {
                let logData = ScheduleLogData(hiddenID: hiddenID, stats: defaultstats)
                schedulerecords.append(logData)
                Logger.process.debugMessageOnly("Execute: getstats() FAILED")

                if SharedReference.shared.silencemissingstats == false {
                    let error = err
                    SharedReference.shared.errorobject?.alert(error: error)
                }
            }
        }

        guard !(stackoftasks?.isEmpty ?? true) else {
            let update = Logging(profile: structprofile,
                                 configurations: localconfigurations)
            let updateconfigurations = update.setCurrentDateOnConfiguration(configrecords: configrecords)
            // Send date stamped configurations back to caller
            localupdateconfigurations(updateconfigurations)

            Logger.process.debugMessageOnly("Execute: EXECUTION is completed")
            guard SharedReference.shared.addsummarylogrecord else { return }
            // Update logrecords
            do {
                try update.addLogToPermanentStore(scheduleRecords: schedulerecords)
            } catch { return }

            // Release streaming references when completed
            activeStreamingProcess = nil
            streamingHandlers = nil
            SharedReference.shared.updateprocess(nil)
            // If logging details to file it must be here
            return
        }
        // Execute next task
        // Release references before starting next to avoid growth
        activeStreamingProcess = nil
        streamingHandlers = nil
        startexecution()
    }

    private func processTermination_noestimation(stringoutputfromrsync: [String]?, _ hiddenID: Int?) {
        // If snahost task the snapshotnum is increased when updating the configuration.
        // When creating the logrecord, decrease the snapshotum by 1

        var suboutput: [String]?
        guard let hiddenID else { return }

        let element = ScheduleLogData(hiddenID: hiddenID, stats: Date().en_string_from_date())
        configrecords.append(element)
        if let config = getConfig(hiddenID) {
            if (stringoutputfromrsync?.count ?? 0) > SharedReference.shared.alerttagginglines, let stringoutputfromrsync {
                suboutput = PrepareOutputFromRsync().prepareOutputFromRsync(stringoutputfromrsync)
            } else {
                suboutput = stringoutputfromrsync
            }

            if SharedReference.shared.addsummarylogrecord {
                let record = RemoteDataNumbers(stringoutputfromrsync: suboutput,
                                               config: config)
                if let stats = record.stats {
                    let element = ScheduleLogData(hiddenID: hiddenID, stats: stats)
                    schedulerecords.append(element)
                    localnoestprogressdetails?.appendRecordExecutedList(record)
                    localnoestprogressdetails?.appendUUIDWithDataToSynchronize(config.id)
                }
            }

            guard !(stackoftasks?.isEmpty ?? true) else {
                let update = Logging(profile: structprofile,
                                     configurations: localconfigurations)
                let updateconfigurations = update.setCurrentDateOnConfiguration(configrecords: configrecords)
                // Send date stamped configurations back to caller
                localupdateconfigurations(updateconfigurations)
                localnoestprogressdetails?.executeAllTasksNoEstimationComplete()
                Logger.process.debugMessageOnly("Execute: execution is completed")
                guard SharedReference.shared.addsummarylogrecord else { return }
                // Update logrecords
                do {
                    try update.addLogToPermanentStore(scheduleRecords: schedulerecords)
                } catch { return }
                // Release streaming references when completed
                activeStreamingProcess = nil
                streamingHandlers = nil
                return
            }
            // Execute next task
            // Release references before starting next to avoid growth
            activeStreamingProcess = nil
            streamingHandlers = nil
            startexecution_noestimate()
        }
    }
}

/* swiftlint:enable cyclomatic_complexity */
