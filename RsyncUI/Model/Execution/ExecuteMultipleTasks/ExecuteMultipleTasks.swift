//
//  ExecuteMultipleTasks.swift
//  RsyncSwiftUI
//
//  Created by Thomas Evensen on 22/01/2021.
//
// swiftlint:disable line_length

import Foundation

typealias Typelogdata = (Int, String)

final class ExecuteMultipleTasks {
    private var localconfigurations: RsyncUIconfigurations?
    private var structprofile: String?
    private var privatehiddenID: Int?
    private var stackoftasktobeexecuted: [Int]?
    private var records: [RemoteinfonumbersOnetask]?
    private var max: Int?
    // Set if abort is executed
    private var setabort = false
    // output from rsync
    private var outputfromrsync: [String]?

    weak var multipletaskstate: MultipleTaskState?
    // weak var estimateprogressdetails: EstimateProgressDetails?
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
            // estimateprogressdetails?.setmaxcount(stackoftasktobeexecuted?.count ?? 0)
        }
    }

    private func startexecution() {
        guard (stackoftasktobeexecuted?.count ?? 0) > 0 else { return }
        if let hiddenID = stackoftasktobeexecuted?.remove(at: 0) {
            privatehiddenID = hiddenID
            executeprogressdetails?.hiddenIDatwork = hiddenID
            let estimation = ExecuteOneTask(hiddenID: hiddenID,
                                            configurations: localconfigurations,
                                            termination: processtermination,
                                            filehandler: filehandler)
            estimation.startexecution()
        }
    }

    @discardableResult
    init(uuids: Set<UUID>,
         profile: String?,
         configurations: RsyncUIconfigurations?,
         multipletaskstateDelegate: MultipleTaskState?,
         // estimateprogressdetailsDelegate: EstimateProgressDetails?,
         executeprogressdetailsDelegate: ExecuteProgressDetails?)
    {
        structprofile = profile
        localconfigurations = configurations
        multipletaskstate = multipletaskstateDelegate
        // estimateprogressdetails = estimateprogressdetailsDelegate
        executeprogressdetails = executeprogressdetailsDelegate
        guard uuids.count > 0 else {
            multipletaskstate?.updatestate(state: .completed)
            return
        }
        guard localconfigurations?.getallconfigurations()?.filter({ uuids.contains($0.id) }).count ?? 0 > 0 else { return }
        prepareandstartexecutetasks(configurations: localconfigurations?.getallconfigurations()?.filter { uuids.contains($0.id) })
        records = [RemoteinfonumbersOnetask]()
        startexecution()
    }

    deinit {
        self.stackoftasktobeexecuted = nil
    }

    func abort() {
        stackoftasktobeexecuted = nil
        // estimateprogressdetails?.resetcounts()
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
        // Log records
        // estimateprogressdetails?.updatetasksinprogresscount(Double((max ?? 0) - (stackoftasktobeexecuted?.count ?? 0)))
        let record = RemoteinfonumbersOnetask(hiddenID: privatehiddenID,
                                              outputfromrsync: outputfromrsync,
                                              config: localconfigurations?.getconfig(hiddenID: privatehiddenID ?? -1))
        records?.append(record)
        guard stackoftasktobeexecuted?.count ?? 0 > 0 else {
            multipletaskstate?.updatestate(state: .completed)
            // estimateprogressdetails?.setmaxcount(0)
            // estimateprogressdetails?.setestimatedlist(records)
            let update = MultipletasksPrimaryLogging(profile: structprofile,
                                                     hiddenID: privatehiddenID,
                                                     configurations: localconfigurations?.getallconfigurations(),
                                                     validhiddenIDs: localconfigurations?.validhiddenIDs ?? Set())
            update.setCurrentDateonConfiguration(configrecords: configrecords)
            update.addlogpermanentstore(schedulerecords: schedulerecords)
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
        executeprogressdetails?.setcurrentprogress(Double(count))
    }
}

// swiftlint:enable line_length
