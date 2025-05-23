//
//  ExecuteMultipleTasks.swift
//  RsyncSwiftUI
//
//  Created by Thomas Evensen on 22/01/2021.
//
// swiftlint:disable line_length

import Foundation
import OSLog
import ParseRsyncOutput

typealias Typelogdata = (Int, String)

@MainActor
final class ExecuteMultipleTasks {
    private var localconfigurations: [SynchronizeConfiguration]
    private var structprofile: String?
    private var stackoftasktobeexecuted: [Int]?
    private var setabort = false

    weak var executestate: ExecuteState?
    weak var executeprogressdetails: ExecuteProgressDetails?
    // Collect loggdata for later save to permanent storage (hiddenID, log)
    private var configrecords = [Typelogdata]()
    private var schedulerecords = [Typelogdata]()
    // Report progress to caller
    var localfilehandler: (Int) -> Void
    // Update configigurations
    var localupdateconfigurations: ([SynchronizeConfiguration]) -> Void

    private func prepareandstartexecutetasks(configurations: [SynchronizeConfiguration]?) {
        if let configurations {
            stackoftasktobeexecuted = configurations.map(\.hiddenID)
        }
    }

    private func startexecution() {
        guard (stackoftasktobeexecuted?.count ?? 0) > 0 else { return }
        if let hiddenID = stackoftasktobeexecuted?.remove(at: 0) {
            executeprogressdetails?.hiddenIDatwork = hiddenID
            let execute = ExecuteOneTask(hiddenID: hiddenID,
                                         configurations: localconfigurations,
                                         processtermination: processtermination,
                                         filehandler: localfilehandler)
            execute.startexecution()
        }
    }

    @discardableResult
    init(profile: String?,
         rsyncuiconfigurations: [SynchronizeConfiguration],
         selecteduuids: Set<UUID>,
         executestateDelegate: ExecuteState?,
         executeprogressdetailsDelegate: ExecuteProgressDetails?,
         filehandler: @escaping (Int) -> Void,
         updateconfigurations: @escaping ([SynchronizeConfiguration]) -> Void)
    {
        structprofile = profile
        localconfigurations = rsyncuiconfigurations
        executestate = executestateDelegate
        executeprogressdetails = executeprogressdetailsDelegate
        localfilehandler = filehandler
        localupdateconfigurations = updateconfigurations
        guard selecteduuids.count > 0 else {
            Logger.process.warning("class ExecuteMultipleTasks, guard uuids.count > 0: \(selecteduuids.count, privacy: .public)")
            executestate?.updateexecutestate(state: .completed)
            return
        }
        let taskstosynchronize = localconfigurations.filter { selecteduuids.contains($0.id) && $0.task != SharedReference.shared.halted }
        guard taskstosynchronize.count > 0 else {
            Logger.process.warning("class ExecuteMultipleTasks, guard uuids.contains($0.id): \(selecteduuids.count, privacy: .public)")
            executestate?.updateexecutestate(state: .completed)
            return
        }

        prepareandstartexecutetasks(configurations: taskstosynchronize)
        startexecution()
    }

    deinit {
        self.stackoftasktobeexecuted = nil
    }
}

extension ExecuteMultipleTasks {
    func processtermination(stringoutputfromrsync: [String]?, _ hiddenID: Int?) {
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
        guard stackoftasktobeexecuted?.count ?? 0 > 0 else {
            let update = Logging(profile: structprofile,
                                 configurations: localconfigurations)
            let updateconfigurations = update.setCurrentDateonConfiguration(configrecords: configrecords)
            // Send date stamped configurations back to caller
            localupdateconfigurations(updateconfigurations)
            // Update logrecords
            update.addlogpermanentstore(schedulerecords: schedulerecords)
            executestate?.updateexecutestate(state: .completed)
            return
        }
        if let hiddenID = stackoftasktobeexecuted?.remove(at: 0) {
            executeprogressdetails?.hiddenIDatwork = hiddenID
            let execution = ExecuteOneTask(hiddenID: hiddenID,
                                           configurations: localconfigurations,
                                           processtermination: processtermination,
                                           filehandler: localfilehandler)
            execution.startexecution()
        }
    }
}

// swiftlint:enable line_length
