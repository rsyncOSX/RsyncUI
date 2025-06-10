//
//  EstimateExecute.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 10/06/2025.
//

import Foundation
import OSLog
import ParseRsyncOutput

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
    weak var localexecutestate: ExecuteState?
    weak var localnoestimationprogressdetails: NoEstimationProgressDetails?
    
    // Collect loggdata for later save to permanent storage (hiddenID, log)
    private var configrecords = [Typelogdata]()
    private var schedulerecords = [Typelogdata]()
    // Report progress to caller
    var localfilehandler: (Int) -> Void
    // Update configurations
    var localupdateconfigurations: ([SynchronizeConfiguration]) -> Void

    var stackoftasks: [Int]?
    var synchronizeIDwitherror: String = ""
    
    func getconfig(_ hiddenID: Int) -> SynchronizeConfiguration? {
        if let index = localconfigurations.firstIndex(where: { $0.hiddenID == hiddenID }) {
            return localconfigurations[index]
        }
        return nil
    }

    private func startestimation() {
        guard (stackoftasks?.count ?? 0) > 0 else { return }
        if let localhiddenID = stackoftasks?.removeFirst() {
            if let config = getconfig(localhiddenID) {
                if let arguments = ArgumentsSynchronize(config: config).argumentssynchronize(dryRun: true,
                                                                                             forDisplay: false)
                {
                    guard arguments.count > 0 else { return }
                    // Used to display details of configuration in estimation
                    localprogressdetails?.configurationtobestimated = config.id
                    let process = ProcessRsync(arguments: arguments,
                                               config: config,
                                               processtermination: processtermination_estimation)
                    process.executeProcess()
                }
            }
        }
    }

    private func startexecution() {
        guard (stackoftasks?.count ?? 0) > 0 else { return }
        if let localhiddenID = stackoftasks?.removeFirst() {
            localprogressdetails?.hiddenIDatwork = localhiddenID
            if let config = getconfig(localhiddenID) {
                if let arguments = ArgumentsSynchronize(config: config).argumentssynchronize(dryRun: false,
                                                                                                 forDisplay: false)
                {
                    let process = ProcessRsync(arguments: arguments,
                                               config: config,
                                               processtermination: processtermination_excute,
                                               filehandler: localfilehandler)
                    process.executeProcess()
                }
            }
        }
    }
    
    private func startexecution_noestimate() {
        if let localhiddenID = stackoftasks?.removeLast() {
            if let config = getconfig(localhiddenID) {
                if let arguments = ArgumentsSynchronize(config: config).argumentssynchronize(dryRun: false,
                                                                                             forDisplay: false)
                {
                    let process = ProcessRsync(arguments: arguments,
                                               config: config,
                                               processtermination: processtermination_noestimation)
                    process.executeProcess()
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

    // convenience init Estimate
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

    // Estimate init, filehandler and updateconfigurations are
    // handled in convenience init for Estimate
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

        // Estimate selected configurations
        if selecteduuids.count > 0 {
            let configurations = localconfigurations.filter { selecteduuids.contains($0.id) && $0.task != SharedReference.shared.halted }
            stackoftasks = configurations.map(\.hiddenID)
        } else {
            // Or estimate all tasks
            let configurations = localconfigurations.filter { $0.task != SharedReference.shared.halted }
            stackoftasks = configurations.map(\.hiddenID)
        }

        localprogressdetails?.setprofileandnumberofconfigurations(structprofile, localconfigurations.count)
        startestimation()
    }

    private func prepareandstartexecutetasks(configurations: [SynchronizeConfiguration]?) {
        if let configurations {
            stackoftasks = configurations.map(\.hiddenID)
        }
    }

    // Execute init
    @discardableResult
    init(profile: String?,
         configurations: [SynchronizeConfiguration],
         selecteduuids: Set<UUID>,
         executestate: ExecuteState?,
         progressdetails: ProgressDetails?,
         filehandler: @escaping (Int) -> Void,
         updateconfigurations: @escaping ([SynchronizeConfiguration]) -> Void)
    {
        structprofile = profile
        localconfigurations = configurations
        localexecutestate = executestate
        localprogressdetails = progressdetails
        localfilehandler = filehandler
        localupdateconfigurations = updateconfigurations

        guard selecteduuids.count > 0 else {
            Logger.process.warning("EstimateExecute: guard uuids.count > 0: \(selecteduuids.count, privacy: .public)")
            localexecutestate?.updateexecutestate(state: .completed)
            return
        }

        let taskstosynchronize = localconfigurations.filter { selecteduuids.contains($0.id) && $0.task != SharedReference.shared.halted }

        guard taskstosynchronize.count > 0 else {
            Logger.process.warning("EstimateExecute: guard uuids.contains($0.id): \(selecteduuids.count, privacy: .public)")
            localexecutestate?.updateexecutestate(state: .completed)
            return
        }

        prepareandstartexecutetasks(configurations: taskstosynchronize)
        startexecution()
    }
    
    // Init execute NO estimation
    @discardableResult
    init(profile: String?,
         configurations: [SynchronizeConfiguration],
         selecteduuids: Set<UUID>,
         noestimationprogressdetails: NoEstimationProgressDetails?,
         filehandler: @escaping (Int) -> Void,
         updateconfigurations: @escaping ([SynchronizeConfiguration]) -> Void)
    {
        structprofile = profile
        localconfigurations = configurations
        localnoestimationprogressdetails = noestimationprogressdetails
        localfilehandler = filehandler
        localupdateconfigurations = updateconfigurations
        // Estimate selected configurations
        if selecteduuids.count > 0 {
            let configurations = localconfigurations.filter { selecteduuids.contains($0.id) && $0.task != SharedReference.shared.halted }
            stackoftasks = configurations.map(\.hiddenID)
        } else {
            let configurations = localconfigurations.filter { $0.task != SharedReference.shared.halted }
            stackoftasks = configurations.map(\.hiddenID)
        }
        startexecution_noestimate()
    }
    
    // convenience init execute NO estimation
    @discardableResult
    convenience init(profile: String?,
         configurations: [SynchronizeConfiguration],
         selecteduuids: Set<UUID>,
         noestimationprogressdetails: NoEstimationProgressDetails?,
         updateconfigurations: @escaping ([SynchronizeConfiguration]) -> Void)
    {
        let filehandler: (Int) -> Void = { _ in
            Logger.process.info("EstimateExecute: You should not SEE this message")
        }
    
        self.init(profile: profile,
                  configurations: configurations,
                  selecteduuids: selecteduuids,
                  noestimationprogressdetails: noestimationprogressdetails,
                  filehandler: filehandler,
                  updateconfigurations: updateconfigurations)
    }
        

    deinit {
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
                    await CreateOutputforviewOutputRsync().createoutputforviewoutputrsync(stringoutputfromrsync)
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
                    await CreateOutputforviewOutputRsync().createoutputforviewoutputrsync(stringoutputfromrsync)
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
            localexecutestate?.updateexecutestate(state: .completed)
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
                localnoestimationprogressdetails?.appendrecordexecutedlist(record)
                localnoestimationprogressdetails?.appenduuidwithdatatosynchronize(config.id)
            }
            
            guard stackoftasks?.count ?? 0 > 0 else {
                let update = Logging(profile: structprofile,
                                     configurations: localconfigurations)
                let updateconfigurations = update.setCurrentDateonConfiguration(configrecords: configrecords)
                // Send date stamped configurations back to caller
                localupdateconfigurations(updateconfigurations)
                // Update logrecords
                update.addlogpermanentstore(schedulerecords: schedulerecords)
                localnoestimationprogressdetails?.executealltasksnoestiamtioncomplete()
                Logger.process.info("EstimateExecute: execution is completed")
                return
            }
            // Execute next task
            startexecution_noestimate()
        }
    }
}

// swiftlint: enable line_length
