//
//  ExecuteTasksAsync.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 22/10/2022.
//
// swiftlint:disable line_length

import Foundation
import OSLog

final class ExecuteTasksAsync {
    var structprofile: String?
    var localconfigurations: RsyncUIconfigurations?
    var stackoftasktobeestimated: [Int]?
    weak var localexecuteprogressdetails: ExecuteProgressDetails?
    // Collect loggdata for later save to permanent storage
    // (hiddenID, log)
    private var configrecords = [Typelogdata]()
    private var schedulerecords = [Typelogdata]()

    @MainActor
    func startexecution() async {
        guard stackoftasktobeestimated?.count ?? 0 > 0 else {
            let update = MultipletasksPrimaryLogging(profile: structprofile,
                                                     hiddenID: -1,
                                                     configurations: localconfigurations?.getallconfigurations(),
                                                     validhiddenIDs: localconfigurations?.validhiddenIDs ?? Set())
            update.setCurrentDateonConfiguration(configrecords: configrecords)
            update.addlogpermanentstore(schedulerecords: schedulerecords)
            localexecuteprogressdetails?.asyncexecutealltasksnoestiamtioncomplete()
            Logger.process.info("class ExecuteTasksAsync: async execution is completed")
            return
        }
        let localhiddenID = stackoftasktobeestimated?.removeLast()
        guard localhiddenID != nil else { return }
        if let config = localconfigurations?.getconfig(hiddenID: localhiddenID ?? 0) {
            let arguments = Argumentsforrsync().argumentsforrsync(config: config, argtype: .arg)
            guard arguments.count > 0 else { return }
            // Check if ShellOut is active
            if config.pretask?.isEmpty == false, config.executepretask == 1 {
                let processshellout = RsyncProcessAsyncShellOut(arguments: arguments,
                                                                config: config,
                                                                processtermination: processterminationexecute)
                await processshellout.executeProcess()
            } else {
                let process = RsyncProcessAsync(arguments: arguments,
                                                config: config,
                                                processtermination: processterminationexecute)
                await process.executeProcess()
            }
        }
    }

    init(profile: String?,
         configurations: RsyncUIconfigurations?,
         executeprogressdetails: ExecuteProgressDetails?,
         uuids: Set<UUID>,
         filter: String)
    {
        structprofile = profile
        localconfigurations = configurations
        localexecuteprogressdetails = executeprogressdetails
        let filteredconfigurations = localconfigurations?.getallconfigurations()?.filter { filter.isEmpty ? true : $0.backupID.contains(filter) }
        stackoftasktobeestimated = [Int]()
        // Estimate selected configurations
        if uuids.count > 0 {
            let configurations = filteredconfigurations?.filter { uuids.contains($0.id) }
            for i in 0 ..< (configurations?.count ?? 0) {
                let task = configurations?[i].task
                if SharedReference.shared.synctasks.contains(task ?? "") {
                    if let hiddenID = configurations?[i].hiddenID {
                        stackoftasktobeestimated?.append(hiddenID)
                    }
                }
            }
        } else {
            // Or estimate all tasks
            for i in 0 ..< (filteredconfigurations?.count ?? 0) {
                let task = filteredconfigurations?[i].task
                if SharedReference.shared.synctasks.contains(task ?? "") {
                    if let hiddenID = filteredconfigurations?[i].hiddenID {
                        stackoftasktobeestimated?.append(hiddenID)
                    }
                }
            }
        }
        localexecuteprogressdetails?.setmaxcount(stackoftasktobeestimated?.count ?? 0)
        localexecuteprogressdetails?.setprofileandnumberofconfigurations(structprofile ?? "Default profile", localconfigurations?.getallconfigurations()?.count ?? 0)
    }

    deinit {
        // print("deinit EstimationOnetask")
    }
}

extension ExecuteTasksAsync {
    func processterminationexecute(outputfromrsync: [String]?, hiddenID: Int?) {
        // Log records
        // If snahost task the snapshotnum is increased when updating the configuration.
        // When creating the logrecord, decrease the snapshotum by 1
        configrecords.append((hiddenID ?? -1, Date().en_us_string_from_date()))
        schedulerecords.append((hiddenID ?? -1, Numbers(outputfromrsync ?? []).stats()))
        let record = RemoteDataNumbers(hiddenID: hiddenID,
                                       outputfromrsync: outputfromrsync,
                                       config: localconfigurations?.getconfig(hiddenID: hiddenID ?? -1))
        localexecuteprogressdetails?.appendrecordexecutedlist(record)
        if let config = localconfigurations?.getconfig(hiddenID: hiddenID ?? -1) {
            localexecuteprogressdetails?.appenduuid(config.id)
        }

        Task {
            await self.startexecution()
        }
    }
}

// swiftlint:enable line_length
