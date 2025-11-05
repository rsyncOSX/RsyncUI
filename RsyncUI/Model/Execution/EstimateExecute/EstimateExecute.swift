//
//  EstimateExecute.swift
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
            "There are errors in tagging data\n for synchronize ID \(idwitherror)\nMost likely number of rows\n> 20 lines and no data to synchronize"
        }
    }
}

typealias Typelogdata = (Int, String)

@MainActor
final class EstimateExecute {
    private var localconfigurations: [SynchronizeConfiguration]
    private var structprofile: String?
    private var setabort = false

    weak var localprogressdetails: ProgressDetails?
    weak var localnoestprogressdetails: NoEstProgressDetails?

    // Collect loggdata for later save to permanent storage (hiddenID, log)
    private var configrecords = [Typelogdata]()
    private var schedulerecords = [Typelogdata]()
    // Report progress to caller
    var localfilehandler: (Int) -> Void
    // Update configurations
    var localupdateconfigurations: ([SynchronizeConfiguration]) -> Void

    var stackoftasks: [Int]?
    var synchronizeIDwitherror: String = ""

    private func getconfig(_ hiddenID: Int) -> SynchronizeConfiguration? {
        if let index = localconfigurations.firstIndex(where: { $0.hiddenID == hiddenID }) {
            return localconfigurations[index]
        }
        return nil
    }

    private func startestimation() {
        guard (stackoftasks?.count ?? 0) > 0 else { return }

        let handlers = ProcessHandlers(
            processtermination: processtermination_estimation,
            filehandler: { _ in
                Logger.process.info("ProcessRsync: You should not SEE this message")
            },
            rsyncpath: GetfullpathforRsync().rsyncpath,
            checklineforerror: TrimOutputFromRsync().checkforrsyncerror,
            updateprocess: SharedReference.shared.updateprocess,
            propogateerror: { error in
                SharedReference.shared.errorobject?.alert(error: error)
            },
            logger: { command, output in
                _ = await ActorLogToFile(command, output)
            },
            checkforerrorinrsyncoutput: SharedReference.shared.checkforerrorinrsyncoutput,
            rsyncversion3: SharedReference.shared.rsyncversion3,
            environment: MyEnvironment()?.environment
        )

        if let localhiddenID = stackoftasks?.removeFirst() {
            if let config = getconfig(localhiddenID) {
                if let arguments = ArgumentsSynchronize(config: config).argumentssynchronize(dryRun: true,
                                                                                             forDisplay: false)
                {
                    // Used to display details of configuration in estimation
                    localprogressdetails?.configurationtobestimated = config.id

                    // Must check valid rsync exists
                    guard SharedReference.shared.norsync == false else { return }
                    guard config.task != SharedReference.shared.halted else { return }

                    let process = ProcessRsync(arguments: arguments,
                                               hiddenID: config.hiddenID,
                                               handlers: handlers,
                                               usefilehandler: false)

                    do {
                        try process.executeProcess()
                    } catch let e {
                        let error = e
                        SharedReference.shared.errorobject?.alert(error: error)
                    }
                }
            }
        }
    }

    private func startexecution() {
        guard (stackoftasks?.count ?? 0) > 0 else { return }

        let handlers = ProcessHandlers(
            processtermination: processtermination_excute,
            filehandler: localfilehandler,
            rsyncpath: GetfullpathforRsync().rsyncpath,
            checklineforerror: TrimOutputFromRsync().checkforrsyncerror,
            updateprocess: SharedReference.shared.updateprocess,
            propogateerror: { error in
                SharedReference.shared.errorobject?.alert(error: error)
            },
            logger: { command, output in
                _ = await ActorLogToFile(command, output)
            },
            checkforerrorinrsyncoutput: SharedReference.shared.checkforerrorinrsyncoutput,
            rsyncversion3: SharedReference.shared.rsyncversion3,
            environment: MyEnvironment()?.environment
        )

        if let localhiddenID = stackoftasks?.removeFirst() {
            // For display progress of synchronization of correct task
            localprogressdetails?.hiddenIDatwork = localhiddenID
            if let config = getconfig(localhiddenID) {
                if let arguments = ArgumentsSynchronize(config: config).argumentssynchronize(dryRun: false,
                                                                                             forDisplay: false)
                {
                    let process = ProcessRsync(arguments: arguments,
                                               hiddenID: config.hiddenID,
                                               handlers: handlers,
                                               usefilehandler: true)
                    // Must check valid rsync exists
                    guard SharedReference.shared.norsync == false else { return }
                    guard config.task != SharedReference.shared.halted else { return }

                    do {
                        try process.executeProcess()
                    } catch let e {
                        let error = e
                        SharedReference.shared.errorobject?.alert(error: error)
                    }
                }
            }
        }
    }

    private func startexecution_noestimate() {
        guard (stackoftasks?.count ?? 0) > 0 else { return }

        let handlers = ProcessHandlers(
            processtermination: processtermination_noestimation,
            filehandler: localfilehandler,
            rsyncpath: GetfullpathforRsync().rsyncpath,
            checklineforerror: TrimOutputFromRsync().checkforrsyncerror,
            updateprocess: SharedReference.shared.updateprocess,
            propogateerror: { error in
                SharedReference.shared.errorobject?.alert(error: error)
            },
            logger: { command, output in
                _ = await ActorLogToFile(command, output)
            },
            checkforerrorinrsyncoutput: SharedReference.shared.checkforerrorinrsyncoutput,
            rsyncversion3: SharedReference.shared.rsyncversion3,
            environment: MyEnvironment()?.environment
        )

        if let localhiddenID = stackoftasks?.removeFirst() {
            if let config = getconfig(localhiddenID) {
                if let arguments = ArgumentsSynchronize(config: config).argumentssynchronize(dryRun: false,
                                                                                             forDisplay: false)
                {
                    // Must check valid rsync exists
                    guard SharedReference.shared.norsync == false else { return }
                    guard config.task != SharedReference.shared.halted else { return }

                    let process = ProcessRsync(arguments: arguments,
                                               hiddenID: config.hiddenID,
                                               handlers: handlers,
                                               usefilehandler: true)

                    do {
                        try process.executeProcess()
                    } catch let e {
                        let error = e
                        SharedReference.shared.errorobject?.alert(error: error)
                    }
                }
            }
        }
    }

    // Used in Estimate
    func validatetagging(_ lines: Int, _ tagged: Bool) throws {
        if lines > SharedReference.shared.alerttagginglines, tagged == false {
            throw ErrorDatatoSynchronize.thereisdatatosynchronize(idwitherror: synchronizeIDwitherror)
        }
    }

    // EXECUTE init, dont need a Convenience init
    // only real init

    @discardableResult
    init(profile: String?,
         configurations: [SynchronizeConfiguration],
         selecteduuids: Set<UUID>,
         progressdetails: ProgressDetails?,
         filehandler: @escaping (Int) -> Void,
         updateconfigurations: @escaping ([SynchronizeConfiguration]) -> Void,
         excutetasks: Bool?)
    {
        structprofile = profile
        localconfigurations = configurations
        localprogressdetails = progressdetails
        localfilehandler = filehandler
        localupdateconfigurations = updateconfigurations

        if excutetasks != nil {
            // Execute tasks
            guard selecteduuids.count > 0 else {
                Logger.process.warning("EstimateExecute: guard uuids.count == 0: \(selecteduuids.count, privacy: .public)")
                return
            }

            let taskstosynchronize = localconfigurations.filter { selecteduuids.contains($0.id) && $0.task != SharedReference.shared.halted }
            stackoftasks = taskstosynchronize.map(\.hiddenID)

            guard stackoftasks?.count ?? 0 > 0 else {
                Logger.process.warning("EstimateExecute: guard uuids.contains($0.id): \(selecteduuids.count, privacy: .public)")
                return
            }
            startexecution()
        }
    }

    /*
     // Convenience init and init for ESTIMATE
     // filehandler and updateconfigurations are not used
     // handled in convenience init for Estimate

     @discardableResult
     convenience init(profile: String?,
                      configurations: [SynchronizeConfiguration],
                      selecteduuids: Set<UUID>,
                      filehandler: @escaping (Int) -> Void,
                      progressdetails: ProgressDetails?)
     {
         let updateconfigurations: ([SynchronizeConfiguration]) -> Void = { _ in
             Logger.process.info("EstimateExecute: You should not SEE this message")
         }
         self.init(profile: profile,
                   configurations: configurations,
                   selecteduuids: selecteduuids,
                   progressdetails: progressdetails,
                   filehandler: filehandler,
                   updateconfigurations: updateconfigurations)
     }

     */
    @discardableResult
    convenience init(profile: String?,
                     configurations: [SynchronizeConfiguration],
                     selecteduuids: Set<UUID>,
                     progressdetails: ProgressDetails?)
    {
        let filehandler: (Int) -> Void = { _ in
            Logger.process.info("EstimateExecute: You should not SEE this message")
        }
        let updateconfigurations: ([SynchronizeConfiguration]) -> Void = { _ in
            Logger.process.info("EstimateExecute: You should not SEE this message")
        }
        self.init(profile: profile,
                  configurations: configurations,
                  selecteduuids: selecteduuids,
                  progressdetails: progressdetails,
                  filehandler: filehandler,
                  updateconfigurations: updateconfigurations)
    }

    @discardableResult
    init(profile: String?,
         configurations: [SynchronizeConfiguration],
         selecteduuids: Set<UUID>,
         progressdetails: ProgressDetails?,
         filehandler: @escaping (Int) -> Void,
         updateconfigurations: @escaping ([SynchronizeConfiguration]) -> Void)
    {
        structprofile = profile
        localconfigurations = configurations
        localprogressdetails = progressdetails
        localfilehandler = filehandler
        localupdateconfigurations = updateconfigurations

        stackoftasks = computestackoftasks(selecteduuids)
        // Add the number of configurations to estimate, used for progress status in estimate
        localprogressdetails?.setprofileandnumberofconfigurations(structprofile, stackoftasks?.count ?? 0)
        startestimation()
    }

    /*
     // Convenience init and init for execute NO ESTIMATION
     // Real init below
     @discardableResult
     convenience init(profile: String?,
                      configurations: [SynchronizeConfiguration],
                      selecteduuids: Set<UUID>,
                      noestprogressdetails: NoEstProgressDetails?,
                      updateconfigurations: @escaping ([SynchronizeConfiguration]) -> Void)
     {
         let filehandler: (Int) -> Void = { _ in
             Logger.process.info("EstimateExecute: You should not SEE this message")
         }

         self.init(profile: profile,
                   configurations: configurations,
                   selecteduuids: selecteduuids,
                   noestprogressdetails: noestprogressdetails,
                   filehandler: filehandler,
                   updateconfigurations: updateconfigurations)
     }

     */
    // Init execute NO estimation
    @discardableResult
    init(profile: String?,
         configurations: [SynchronizeConfiguration],
         selecteduuids: Set<UUID>,
         noestprogressdetails: NoEstProgressDetails?,
         filehandler: @escaping (Int) -> Void,
         updateconfigurations: @escaping ([SynchronizeConfiguration]) -> Void)
    {
        structprofile = profile
        localconfigurations = configurations
        localnoestprogressdetails = noestprogressdetails
        localfilehandler = filehandler
        localupdateconfigurations = updateconfigurations

        stackoftasks = computestackoftasks(selecteduuids)
        startexecution_noestimate()
    }

    private func computestackoftasks(_ selecteduuids: Set<UUID>) -> [Int] {
        if selecteduuids.count > 0 {
            let configurations = localconfigurations.filter { selecteduuids.contains($0.id) && $0.task != SharedReference.shared.halted }
            return configurations.map(\.hiddenID)
        } else {
            // Or go for all
            let configurations = localconfigurations.filter { $0.task != SharedReference.shared.halted }
            return configurations.map(\.hiddenID)
        }
    }

    deinit {
        Logger.process.info("EstimateExecute: DEINIT")
        self.stackoftasks = nil
    }
}

extension EstimateExecute {
    func processtermination_estimation(stringoutputfromrsync: [String]?, _ hiddenID: Int?) {
        var adjustedoutputfromrsync = false
        var suboutput: [String]?

        if (stringoutputfromrsync?.count ?? 0) > 20, let stringoutputfromrsync {
            adjustedoutputfromrsync = true
            suboutput = PrepareOutputFromRsync().prepareOutputFromRsync(stringoutputfromrsync)
        }

        if adjustedoutputfromrsync {
            var record = RemoteDataNumbers(stringoutputfromrsync: suboutput,
                                           config: getconfig(hiddenID ?? -1))
            adjustedoutputfromrsync = false
            Task {
                // Create data for output rsync for view
                record.outputfromrsync =
                    await ActorCreateOutputforView().createaoutputforview(stringoutputfromrsync)
                localprogressdetails?.appendrecordestimatedlist(record)

                if record.datatosynchronize {
                    if let config = getconfig(hiddenID ?? -1) {
                        localprogressdetails?.appenduuidwithdatatosynchronize(config.id)
                    }
                }

                // Validate that tagging is correct
                do {
                    // In case of throwing an error to identify which task
                    synchronizeIDwitherror = record.backupID
                    try validatetagging(stringoutputfromrsync?.count ?? 0, record.datatosynchronize)
                } catch let e {
                    let error = e
                    SharedReference.shared.errorobject?.alert(error: error)
                }

                guard stackoftasks?.count ?? 0 > 0 else {
                    localprogressdetails?.estimationiscomplete()
                    Logger.process.info("EstimateExecute: estimation is completed")
                    return
                }
                // Estimate next task
                startestimation()
            }
        } else {
            var record = RemoteDataNumbers(stringoutputfromrsync: stringoutputfromrsync,
                                           config: getconfig(hiddenID ?? -1))
            Task {
                // Create data for output rsync for view
                record.outputfromrsync =
                    await ActorCreateOutputforView().createaoutputforview(stringoutputfromrsync)
                localprogressdetails?.appendrecordestimatedlist(record)

                if record.datatosynchronize {
                    if let config = getconfig(hiddenID ?? -1) {
                        localprogressdetails?.appenduuidwithdatatosynchronize(config.id)
                    }
                }

                // Validate that tagging is correct
                do {
                    try validatetagging(stringoutputfromrsync?.count ?? 0, record.datatosynchronize)
                } catch let e {
                    let error = e
                    SharedReference.shared.errorobject?.alert(error: error)
                }

                guard stackoftasks?.count ?? 0 > 0 else {
                    localprogressdetails?.estimationiscomplete()
                    Logger.process.info("EstimateExecute: estimation is completed")
                    return
                }
                // Estimate next task
                startestimation()
            }
        }
    }

    func processtermination_excute(stringoutputfromrsync: [String]?, _ hiddenID: Int?) {
        guard setabort == false else { return }
        // Log records
        // If snahost task the snapshotnum is increased when updating the configuration.
        // When creating the logrecord, decrease the snapshotum by 1
        configrecords.append((hiddenID ?? -1, Date().en_string_from_date()))
        // Prepareoutput prepares output from rsync for extracting the numbers only.
        // It removes all lines except the last 20 lines where summarized numbers are put
        let preparedoutputfromrsync = PrepareOutputFromRsync().prepareOutputFromRsync(stringoutputfromrsync)
        if let stats = ParseRsyncOutput(preparedoutputfromrsync,
                                        SharedReference.shared.rsyncversion3).stats
        {
            schedulerecords.append((hiddenID ?? -1, stats))
        }
        guard stackoftasks?.count ?? 0 > 0 else {
            let update = Logging(profile: structprofile,
                                 configurations: localconfigurations)
            let updateconfigurations = update.setCurrentDateonConfiguration(configrecords: configrecords)
            // Send date stamped configurations back to caller
            localupdateconfigurations(updateconfigurations)
            // Update logrecords
            update.addlogpermanentstore(schedulerecords: schedulerecords)
            Logger.process.info("EstimateExecute: execution is completed")
            return
        }
        // Execute next task
        startexecution()
    }

    func processtermination_noestimation(stringoutputfromrsync: [String]?, _ hiddenID: Int?) {
        // If snahost task the snapshotnum is increased when updating the configuration.
        // When creating the logrecord, decrease the snapshotum by 1

        var suboutput: [String]?

        configrecords.append((hiddenID ?? -1, Date().en_string_from_date()))
        if let config = getconfig(hiddenID ?? -1) {
            if (stringoutputfromrsync?.count ?? 0) > 20, let stringoutputfromrsync {
                suboutput = PrepareOutputFromRsync().prepareOutputFromRsync(stringoutputfromrsync)
            } else {
                suboutput = stringoutputfromrsync
            }

            let record = RemoteDataNumbers(stringoutputfromrsync: suboutput,
                                           config: config)
            if let stats = record.stats {
                schedulerecords.append((hiddenID ?? -1, stats))
                localnoestprogressdetails?.appendrecordexecutedlist(record)
                localnoestprogressdetails?.appenduuidwithdatatosynchronize(config.id)
            }

            guard stackoftasks?.count ?? 0 > 0 else {
                let update = Logging(profile: structprofile,
                                     configurations: localconfigurations)
                let updateconfigurations = update.setCurrentDateonConfiguration(configrecords: configrecords)
                // Send date stamped configurations back to caller
                localupdateconfigurations(updateconfigurations)
                // Update logrecords
                update.addlogpermanentstore(schedulerecords: schedulerecords)
                localnoestprogressdetails?.executealltasksnoestiamtioncomplete()
                Logger.process.info("EstimateExecute: execution is completed")
                return
            }
            // Execute next task
            startexecution_noestimate()
        }
    }
}

// swiftlint: enable line_length
