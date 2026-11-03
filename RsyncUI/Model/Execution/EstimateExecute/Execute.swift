//
//  Execute.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 10/06/2025.
//

import Foundation
import OSLog
import ParseRsyncOutput
import RsyncProcessStreaming

@MainActor
final class Execute {
    private var localconfigurations: [SynchronizeConfiguration]
    private var structprofile: String?

    weak var localprogressdetails: ProgressDetails?
    weak var localnoestprogressdetails: NoEstProgressDetails?

    // Collect loggdata for later save to permanent storage (hiddenID, log)
    private var configrecords = [ScheduleLogData]()
    private var schedulerecords = [ScheduleLogData]()
    /// Report progress to caller
    var localfileHandler: (Int) -> Void
    // Update configurations
    var localupdateconfigurations: ([SynchronizeConfiguration], StreamingProcessOutcome) -> Void
    var stackoftasks: [Int]?
    private var isCancelled = false
    private var isFinalizing = false
    private var isFinished = false
    private var detailLogTasks = [Task<Bool, Never>]()

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

    private func releaseStreamingReferences() {
        activeStreamingProcess = nil
        streamingHandlers = nil
    }

    private func completeExecution() {
        releaseStreamingReferences()
    }

    func cancel() {
        guard !isFinished else { return }
        SharedReference.shared.quitAfterExternalExecution = false
        isCancelled = true
        stackoftasks = nil
        if let process = activeStreamingProcess, process.isRunning {
            process.cancel()
        }
    }

    /// All completion callbacks run only after every requested write has finished.
    private func finalize(_ outcome: StreamingProcessOutcome) {
        guard !isFinalizing, !isFinished else { return }
        isFinalizing = true
        stackoftasks = nil
        Task { [self] in
            var saved = true
            for task in detailLogTasks {
                let result = await task.value
                saved = saved && result
            }
            detailLogTasks.removeAll()
            let update = await Logging.create(profile: structprofile, configurations: localconfigurations)
            let configurations = await update.setCurrentDateOnConfiguration(configrecords: configrecords)
            if SharedReference.shared.addsummarylogrecord {
                do {
                    try await update.addLogToPermanentStore(scheduleRecords: schedulerecords)
                } catch {
                    saved = false
                    SharedReference.shared.errorobject?.alert(error: error)
                }
            }
            saved = saved && update.persistenceSucceeded
            let result: StreamingProcessOutcome = isCancelled ? .cancelled : (saved ? outcome : .failure)
            completeExecution()
            isFinished = true
            SharedReference.shared.executionFinalizationInProgress = false
            localupdateconfigurations(configurations, result)
            if result == .success {
                localnoestprogressdetails?.executeAllTasksNoEstimationComplete()
            }
            SharedReference.shared.finishExternalExecution(success: result == .success)
        }
    }

    private func finishFailedExecution() {
        finalize(isCancelled ? .cancelled : .failure)
    }

    private func logDetails(_ output: [String]?) {
        guard SharedReference.shared.saveactualsynclogdata else { return }
        detailLogTasks.append(Task {
            await ActorLogToFile.shared.logOutput("rsync", output)
        })
    }

    private func startexecution() {
        guard !isCancelled, !(stackoftasks?.isEmpty ?? true) else { return }
        streamingHandlers = CreateStreamingHandlers().createResultHandlers(
            fileHandler: localfileHandler,
            processTermination: { output, hiddenID, outcome in
                self.logDetails(output)
                guard !self.isCancelled, outcome == .success else {
                    self.finishFailedExecution()
                    return
                }
                self.processTermination(stringoutputfromrsync: output, hiddenID)
            }
        )

        if let localhiddenID = stackoftasks?.removeFirst() {
            // For display progress of synchronization of correct task
            localprogressdetails?.hiddenIDatwork = localhiddenID
            if let config = getConfig(localhiddenID), let arguments = ArgumentsSynchronize(config: config).argumentsSynchronize(dryRun: false,
                                                                                                                                forDisplay: false) {
                guard let streamingHandlers else {
                    finishFailedExecution()
                    return
                }
                let process = RsyncProcessStreaming.RsyncProcess(
                    arguments: arguments,
                    hiddenID: config.hiddenID,
                    handlers: streamingHandlers,
                    useFileHandler: true
                )
                // Must check valid rsync exists
                guard SharedReference.shared.norsync == false, config.task != SharedReference.shared.halted else {
                    finishFailedExecution()
                    return
                }

                if SharedReference.shared.validatearguments {
                    do {
                        try ValidateArguments().validate(config: config, arguments: arguments)
                    } catch let err {
                        let error = err
                        SharedReference.shared.errorobject?.alert(error: error)
                        finishFailedExecution()
                        return
                    }
                }

                do {
                    try process.executeProcess()
                    activeStreamingProcess = process
                } catch let err {
                    let error = err
                    SharedReference.shared.errorobject?.alert(error: error)
                    finishFailedExecution()
                }
            } else {
                finishFailedExecution()
            }
        }
    }

    private func startexecution_noestimate() {
        guard !isCancelled, !(stackoftasks?.isEmpty ?? true) else { return }
        streamingHandlers = CreateStreamingHandlers().createResultHandlers(
            fileHandler: localfileHandler,
            processTermination: { output, hiddenID, outcome in
                self.logDetails(output)
                guard !self.isCancelled, outcome == .success else {
                    self.finishFailedExecution()
                    return
                }
                self.processTermination_noestimation(stringoutputfromrsync: output, hiddenID)
            }
        )

        if let localhiddenID = stackoftasks?.removeFirst(), let config = getConfig(localhiddenID), let arguments = ArgumentsSynchronize(config: config).argumentsSynchronize(dryRun: false,
                                                                                                                                                                             forDisplay: false) {
            // Must check valid rsync exists
            guard SharedReference.shared.norsync == false, config.task != SharedReference.shared.halted else {
                finishFailedExecution()
                return
            }

            if SharedReference.shared.validatearguments {
                do {
                    try ValidateArguments().validate(config: config, arguments: arguments)
                } catch let err {
                    let error = err
                    SharedReference.shared.errorobject?.alert(error: error)
                    finishFailedExecution()
                    return
                }
            }
            guard let streamingHandlers else {
                finishFailedExecution()
                return
            }

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
                finishFailedExecution()
            }
        } else {
            finishFailedExecution()
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

    static func start(profile: String?,
                      configurations: [SynchronizeConfiguration],
                      selecteduuids: Set<UUID>,
                      progressdetails: ProgressDetails?,
                      fileHandler: @escaping (Int) -> Void,
                      updateconfigurations: @escaping ([SynchronizeConfiguration], StreamingProcessOutcome) -> Void) -> Execute {
        let execute = Execute(profile: profile,
                              configurations: configurations,
                              selecteduuids: selecteduuids,
                              progressdetails: progressdetails,
                              fileHandler: fileHandler,
                              updateconfigurations: updateconfigurations)
        SharedReference.shared.executionFinalizationInProgress = true
        guard !(execute.stackoftasks?.isEmpty ?? true) else {
            execute.finalize(.success)
            return execute
        }
        Logger.process.debugMessageOnly("Execute: START EXECUTION")
        execute.startexecution()
        return execute
    }

    static func start(profile: String?,
                      configurations: [SynchronizeConfiguration],
                      selecteduuids: Set<UUID>,
                      noestprogressdetails: NoEstProgressDetails?,
                      fileHandler: @escaping (Int) -> Void,
                      updateconfigurations: @escaping ([SynchronizeConfiguration], StreamingProcessOutcome) -> Void) -> Execute {
        let execute = Execute(profile: profile,
                              configurations: configurations,
                              selecteduuids: selecteduuids,
                              noestprogressdetails: noestprogressdetails,
                              fileHandler: fileHandler,
                              updateconfigurations: updateconfigurations)
        SharedReference.shared.executionFinalizationInProgress = true
        guard !(execute.stackoftasks?.isEmpty ?? true) else {
            execute.finalize(.success)
            return execute
        }
        execute.startexecution_noestimate()
        return execute
    }

    private init(profile: String?,
                 configurations: [SynchronizeConfiguration],
                 selecteduuids: Set<UUID>,
                 progressdetails: ProgressDetails?,
                 fileHandler: @escaping (Int) -> Void,
                 updateconfigurations: @escaping ([SynchronizeConfiguration], StreamingProcessOutcome) -> Void) {
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
    }

    @discardableResult
    init(profile: String?,
         configurations: [SynchronizeConfiguration],
         selecteduuids: Set<UUID>,
         noestprogressdetails: NoEstProgressDetails?,
         fileHandler: @escaping (Int) -> Void,
         updateconfigurations: @escaping ([SynchronizeConfiguration], StreamingProcessOutcome) -> Void) {
        structprofile = profile
        localconfigurations = configurations
        localnoestprogressdetails = noestprogressdetails
        localfileHandler = fileHandler
        localupdateconfigurations = updateconfigurations

        stackoftasks = computestackoftasks(selecteduuids)
    }

    deinit {
        Logger.process.debugMessageOnly("Execute: DEINIT")
        self.stackoftasks = nil
    }
}

extension Execute {
    private func processTermination(stringoutputfromrsync: [String]?, _ hiddenID: Int?) {
        guard let hiddenID else {
            finishFailedExecution()
            return
        }

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
            finalize(.success)
            return
        }
        // Execute next task
        // Release references before starting next to avoid growth
        releaseStreamingReferences()
        startexecution()
    }

    private func processTermination_noestimation(stringoutputfromrsync: [String]?, _ hiddenID: Int?) {
        // If snahost task the snapshotnum is increased when updating the configuration.
        // When creating the logrecord, decrease the snapshotum by 1

        var suboutput: [String]?
        guard let hiddenID else {
            finishFailedExecution()
            return
        }

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
                finalize(.success)
                return
            }
            // Execute next task
            // Release references before starting next to avoid growth
            releaseStreamingReferences()
            startexecution_noestimate()
        }
    }
}
