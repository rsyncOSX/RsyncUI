//
//  Execute.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 10/06/2025.
//

import Foundation
import OSLog
import ParseRsyncOutput
import RsyncProcess

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

    private func getConfig(_ hiddenID: Int) -> SynchronizeConfiguration? {
        if let index = localconfigurations.firstIndex(where: { $0.hiddenID == hiddenID }) {
            return localconfigurations[index]
        }
        return nil
    }

    private func startexecution() {
        guard (stackoftasks?.count ?? 0) > 0 else { return }
        let handlers = CreateHandlers().createHandlers(
            fileHandler: localfileHandler,
            processTermination: processTermination
        )

        if let localhiddenID = stackoftasks?.removeFirst() {
            // For display progress of synchronization of correct task
            localprogressdetails?.hiddenIDatwork = localhiddenID
            if let config = getConfig(localhiddenID) {
                if let arguments = ArgumentsSynchronize(config: config).argumentsSynchronize(dryRun: false,
                                                                                             forDisplay: false) {
                    
                    
                    let process = RsyncProcess(arguments: arguments,
                                               hiddenID: config.hiddenID,
                                               handlers: handlers,
                                               useFileHandler: true)
                    // Must check valid rsync exists
                    guard SharedReference.shared.norsync == false else { return }
                    guard config.task != SharedReference.shared.halted else { return }
                    
                    do {
                        try ValidateArguments().validate(config: config, arguments: arguments)
                    } catch let err {
                        let error = err
                        SharedReference.shared.errorobject?.alert(error: error)
                    }

                    do {
                        try process.executeProcess()
                    } catch let err {
                        let error = err
                        SharedReference.shared.errorobject?.alert(error: error)
                    }
                }
            }
        }
    }

    private func startexecution_noestimate() {
        guard (stackoftasks?.count ?? 0) > 0 else { return }

        let handlers = CreateHandlers().createHandlers(
            fileHandler: localfileHandler,
            processTermination: processTermination_noestimation
        )

        if let localhiddenID = stackoftasks?.removeFirst() {
            if let config = getConfig(localhiddenID) {
                if let arguments = ArgumentsSynchronize(config: config).argumentsSynchronize(dryRun: false,
                                                                                             forDisplay: false) {
                    // Must check valid rsync exists
                    guard SharedReference.shared.norsync == false else { return }
                    guard config.task != SharedReference.shared.halted else { return }
                    
                    do {
                        try ValidateArguments().validate(config: config, arguments: arguments)
                    } catch let err {
                        let error = err
                        SharedReference.shared.errorobject?.alert(error: error)
                    }

                    let process = RsyncProcess(arguments: arguments,
                                               hiddenID: config.hiddenID,
                                               handlers: handlers,
                                               useFileHandler: true)

                    do {
                        try process.executeProcess()
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
        guard stackoftasks?.count ?? 0 > 0 else { return }
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
        // Log records
        // If snahost task the snapshotnum is increased when updating the configuration.
        // When creating the logrecord, decrease the snapshotum by 1
        let element = ScheduleLogData(hiddenID: hiddenID ?? -1, stats: Date().en_string_from_date())
        configrecords.append(element)
        // Prepareoutput prepares output from rsync for extracting the numbers only.
        // It removes all lines except the last 20 lines where summarized numbers are put
        let preparedoutputfromrsync = PrepareOutputFromRsync().prepareOutputFromRsync(stringoutputfromrsync)

        if SharedReference.shared.addsummarylogrecord {
            do {
                let stats = try ParseRsyncOutput(preparedoutputfromrsync,
                                                 SharedReference.shared.rsyncversion3 ? .ver3 : .openrsync).getstats()
                let logData = ScheduleLogData(hiddenID: hiddenID ?? -1, stats: stats ?? defaultstats)
                schedulerecords.append(logData)
                Logger.process.debugMessageOnly("Execute: getstats() SUCCESS")
            } catch let err {
                if SharedReference.shared.silencemissingstats == false {
                    let logData = ScheduleLogData(hiddenID: hiddenID ?? -1, stats: defaultstats)
                    schedulerecords.append(logData)
                    Logger.process.debugMessageOnly("Execute: getstats() FAILED")

                    let error = err
                    SharedReference.shared.errorobject?.alert(error: error)

                } else {
                    let logData = ScheduleLogData(hiddenID: hiddenID ?? -1, stats: defaultstats)
                    schedulerecords.append(logData)
                    Logger.process.debugMessageOnly("Execute: getstats() FAILED")
                }
            }
        }

        guard stackoftasks?.count ?? 0 > 0 else {
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

            return
        }
        // Execute next task
        startexecution()
    }

    private func processTermination_noestimation(stringoutputfromrsync: [String]?, _ hiddenID: Int?) {
        // If snahost task the snapshotnum is increased when updating the configuration.
        // When creating the logrecord, decrease the snapshotum by 1

        var suboutput: [String]?

        let element = ScheduleLogData(hiddenID: hiddenID ?? -1, stats: Date().en_string_from_date())
        configrecords.append(element)
        if let config = getConfig(hiddenID ?? -1) {
            if (stringoutputfromrsync?.count ?? 0) > 20, let stringoutputfromrsync {
                suboutput = PrepareOutputFromRsync().prepareOutputFromRsync(stringoutputfromrsync)
            } else {
                suboutput = stringoutputfromrsync
            }

            if SharedReference.shared.addsummarylogrecord {
                let record = RemoteDataNumbers(stringoutputfromrsync: suboutput,
                                               config: config)
                if let stats = record.stats {
                    let element = ScheduleLogData(hiddenID: hiddenID ?? -1, stats: stats)
                    schedulerecords.append(element)
                    localnoestprogressdetails?.appendRecordExecutedList(record)
                    localnoestprogressdetails?.appendUUIDWithDataToSynchronize(config.id)
                }
            }

            guard stackoftasks?.count ?? 0 > 0 else {
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
                return
            }
            // Execute next task
            startexecution_noestimate()
        }
    }
}
