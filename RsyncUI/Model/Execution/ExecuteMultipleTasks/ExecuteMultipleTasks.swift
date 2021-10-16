//
//  ExecuteMultipleTasks.swift
//  RsyncSwiftUI
//
//  Created by Thomas Evensen on 22/01/2021.
//
// swiftlint:disable line_length

import Foundation

typealias Typelogdata = (Int, String)

enum ExecutetaskWork: String, CaseIterable, Identifiable, CustomStringConvertible {
    case start
    case execute
    case completed
    case error

    var id: String { rawValue }
    var description: String { rawValue.localizedCapitalized }
}

final class ExecuteMultipleTasks {
    private var localconfigurationsSwiftUI: ConfigurationsSwiftUI?
    private var structprofile: String?
    private var privatehiddenID: Int?
    private var stackoftasktobeexecuted: [Int]?
    private var outputprocess: OutputfromProcess?
    private var records: [RemoteinfonumbersOnetask]?
    private var max: Int?
    private var uuids: Set<UUID>?
    // Set if abort is executed
    private var setabort = false

    weak var multipletasksateDelegate: MultipleTaskState?
    weak var updateestimationcountDelegate: UpdateEstimationCount?
    // In progress count each task
    weak var updateprogessDelegate: ExecuteDetailsProtocol?

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
            updateestimationcountDelegate?.setmaxcount(num: stackoftasktobeexecuted?.count ?? 0)
        }
    }

    private func startexecution() {
        guard (stackoftasktobeexecuted?.count ?? 0) > 0 else { return }
        if let hiddenID = stackoftasktobeexecuted?.remove(at: 0) {
            privatehiddenID = hiddenID
            updateestimationcountDelegate?.sethiddenID(hiddenID)
            outputprocess = OutputfromProcess()
            let estimation = ExecuteOneTask(hiddenID: hiddenID,
                                            configurationsSwiftUI: localconfigurationsSwiftUI,
                                            outputprocess: outputprocess,
                                            processtermination: processtermination,
                                            filehandler: filehandler)
            estimation.startexecution()
        }
    }

    private func getconfig(hiddenID: Int?) -> Configuration? {
        if let hiddenID = hiddenID {
            if let configurations = localconfigurationsSwiftUI?.getallconfigurations()?.filter({ $0.hiddenID == hiddenID }) {
                guard configurations.count == 1 else { return nil }
                return configurations[0]
            }
        }
        return nil
    }

    init(uuids: Set<UUID>,
         profile: String?,
         configurationsSwiftUI: ConfigurationsSwiftUI?,
         executionstateDelegate: MultipleTaskState?,
         updateinprogresscount: UpdateEstimationCount?,
         singletaskupdate: ExecuteDetailsProtocol?)
    {
        structprofile = profile
        localconfigurationsSwiftUI = configurationsSwiftUI
        multipletasksateDelegate = executionstateDelegate
        updateestimationcountDelegate = updateinprogresscount
        updateprogessDelegate = singletaskupdate
        // Debug print
        // printdebugdata(uuids)
        // Debug print
        guard uuids.count > 0 else { return }
        let configurations = configurationsSwiftUI?.getallconfigurations()?.filter { uuids.contains($0.id) }
        guard configurations?.count ?? 0 > 0 else { return }
        prepareandstartexecutetasks(configurations: configurations)
        records = [RemoteinfonumbersOnetask]()
        startexecution()
    }

    deinit {
        self.stackoftasktobeexecuted = nil
        // print("deinit ExecuteMultipleTasks")
    }

    func abort() {
        stackoftasktobeexecuted = nil
        updateestimationcountDelegate?.resetcounts()
        setabort = true
    }

    // debug
    func printdebugdata(_ uuids: Set<UUID>) {
        let configurations = localconfigurationsSwiftUI?.getallconfigurations()?.filter { uuids.contains($0.id) }
        print("EXECUTION start: \(configurations?.count ?? 0) number of configurations")
        if uuids.count != (configurations?.count ?? 0) {
            print("PROBLEM: clearing old uuids not done properly")
        }
    }
}

extension ExecuteMultipleTasks {
    func processtermination() {
        guard setabort == false else { return }
        // Log records
        // If snahost task the snapshotnum is increased when updating the configuration.
        // When creating the logrecord, decrease the snapshotum by 1
        configrecords.append((privatehiddenID ?? -1, Date().en_us_string_from_date()))
        schedulerecords.append((privatehiddenID ?? -1, Numbers(outputprocess: outputprocess).stats()))
        // Log records
        updateestimationcountDelegate?.updateinprogresscount(num: Double((max ?? 0) - (stackoftasktobeexecuted?.count ?? 0)))
        let record = RemoteinfonumbersOnetask(hiddenID: privatehiddenID,
                                              outputprocess: outputprocess,
                                              config: getconfig(hiddenID: privatehiddenID))
        records?.append(record)
        guard stackoftasktobeexecuted?.count ?? 0 > 0 else {
            multipletasksateDelegate?.updatestate(state: .completed)
            updateestimationcountDelegate?.setmaxcount(num: 0)
            updateestimationcountDelegate?.setestimatedlist(records)
            let update = MultipletasksPrimaryLogging(profile: structprofile,
                                                     hiddenID: privatehiddenID,
                                                     configurations: localconfigurationsSwiftUI?.getallconfigurations(),
                                                     validhiddenIDs: localconfigurationsSwiftUI?.validhiddenIDs ?? Set())
            update.setCurrentDateonConfiguration(configrecords: configrecords)
            update.addlogpermanentstore(schedulerecords: schedulerecords)
            return
        }
        outputprocess = OutputfromProcessRsync()
        if let hiddenID = stackoftasktobeexecuted?.remove(at: 0) {
            privatehiddenID = hiddenID
            updateestimationcountDelegate?.sethiddenID(hiddenID)
            let execution = ExecuteOneTask(hiddenID: hiddenID,
                                           configurationsSwiftUI: localconfigurationsSwiftUI,
                                           outputprocess: outputprocess,
                                           processtermination: processtermination,
                                           filehandler: filehandler)
            execution.startexecution()
        }
    }

    func filehandler() {
        updateprogessDelegate?.setcurrentprogress(Double(outputprocess?.getOutput()?.count ?? 0))
    }
}
