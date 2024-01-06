//
//  ExecuteMultipleTasks.swift
//  RsyncSwiftUI
//
//  Created by Thomas Evensen on 22/01/2021.
//
// swiftlint:disable line_length

import Foundation
import OSLog

typealias Typelogdata = (Int, String)

final class ExecuteMultipleTasks {
    private var localconfigurations: RsyncUIconfigurations?
    private var structprofile: String?
    private var privatehiddenID: Int?
    private var stackoftasktobeexecuted: [Int]?
    // private var records: [RemoteDataNumbers]?
    private var max: Int?
    // Set if abort is executed
    private var setabort = false
    // output from rsync
    private var outputfromrsync: [String]?

    weak var multipletaskstate: ExecuteMultipleTasksState?
    // In progress count each task
    weak var executeprogressdetails: ExecuteProgressDetails?
    // Collect loggdata for later save to permanent storage
    // (hiddenID, log)
    private var configrecords = [Typelogdata]()
    private var schedulerecords = [Typelogdata]()

    private func prepareandstartexecutetasks(configurations: [Configuration]?) {
        stackoftasktobeexecuted = [Int]()
        // Multiple selected indexes
        if let configurations = configurations {
            for i in 0 ..< configurations.count {
                stackoftasktobeexecuted?.append(configurations[i].hiddenID)
            }
            max = stackoftasktobeexecuted?.count
        }
    }

    private func startexecution() {
        guard (stackoftasktobeexecuted?.count ?? 0) > 0 else { return }
        if let hiddenID = stackoftasktobeexecuted?.remove(at: 0) {
            privatehiddenID = hiddenID
            executeprogressdetails?.hiddenIDatwork = hiddenID
            let execute = ExecuteOneTask(hiddenID: hiddenID,
                                         configurations: localconfigurations,
                                         termination: processtermination,
                                         filehandler: filehandler)
            execute.startexecution()
        }
    }

    @discardableResult
    init(uuids: Set<UUID>,
         profile: String?,
         configurations: RsyncUIconfigurations?,
         multipletaskstateDelegate: ExecuteMultipleTasksState?,
         executeprogressdetailsDelegate: ExecuteProgressDetails?)
    {
        structprofile = profile
        localconfigurations = configurations
        multipletaskstate = multipletaskstateDelegate
        executeprogressdetails = executeprogressdetailsDelegate
        guard uuids.count > 0 else {
            Logger.process.warning("class ExecuteMultipleTasks, guard uuids.count > 0: \(uuids.count, privacy: .public)")
            multipletaskstate?.updatestate(state: .completed)
            return
        }
        let taskstosynchronize = localconfigurations?.getallconfigurations()?.filter { uuids.contains($0.id) }
        guard (taskstosynchronize?.count ?? 0) > 0 else {
            Logger.process.warning("class ExecuteMultipleTasks, guard uuids.contains($0.id): \(uuids.count, privacy: .public)")
            multipletaskstate?.updatestate(state: .completed)
            return
        }
        prepareandstartexecutetasks(configurations: taskstosynchronize)
        // records = [RemoteDataNumbers]()
        startexecution()
    }

    deinit {
        self.stackoftasktobeexecuted = nil
    }

    func abort() {
        stackoftasktobeexecuted = nil
        setabort = true
    }
}

extension ExecuteMultipleTasks {
    func processtermination(data: [String]?, hiddenID _: Int?) {
        guard setabort == false else { return }
        // Log records
        // If snahost task the snapshotnum is increased when updating the configuration.
        // When creating the logrecord, decrease the snapshotum by 1
        configrecords.append((privatehiddenID ?? -1, Date().en_us_string_from_date()))
        schedulerecords.append((privatehiddenID ?? -1, Numbers(data ?? []).stats()))
        guard stackoftasktobeexecuted?.count ?? 0 > 0 else {
            let update = MultipletasksPrimaryLogging(profile: structprofile,
                                                     hiddenID: privatehiddenID,
                                                     configurations: localconfigurations?.getallconfigurations(),
                                                     validhiddenIDs: localconfigurations?.validhiddenIDs ?? Set())
            update.setCurrentDateonConfiguration(configrecords: configrecords)
            update.addlogpermanentstore(schedulerecords: schedulerecords)
            multipletaskstate?.updatestate(state: .completed)
            return
        }
        if let hiddenID = stackoftasktobeexecuted?.remove(at: 0) {
            privatehiddenID = hiddenID
            executeprogressdetails?.hiddenIDatwork = hiddenID
            let execution = ExecuteOneTask(hiddenID: hiddenID,
                                           configurations: localconfigurations,
                                           termination: processtermination,
                                           filehandler: filehandler)
            execution.startexecution()
        }
    }

    func filehandler(count: Int) {
        executeprogressdetails?.currenttaskprogress = Double(count)
    }
}

// swiftlint:enable line_length
