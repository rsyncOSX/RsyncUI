//
//  ExecuteTasksAsync14.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 19/11/2023.
//

import Foundation

@available(macOS 14.0, *)
final class ExecuteTasksAsync14: EstimateTasksAsync14 {
    // Collect loggdata for later save to permanent storage
    // (hiddenID, log)
    private var configrecords = [Typelogdata]()
    private var schedulerecords = [Typelogdata]()

    @MainActor
    override func startexecution() async {
        guard stackoftasktobeestimated?.count ?? 0 > 0 else {
            let update = MultipletasksPrimaryLogging(profile: structprofile,
                                                     hiddenID: -1,
                                                     configurations: localconfigurations?.getallconfigurations(),
                                                     validhiddenIDs: localconfigurations?.validhiddenIDs ?? Set())
            update.setCurrentDateonConfiguration(configrecords: configrecords)
            update.addlogpermanentstore(schedulerecords: schedulerecords)
            estimateprogressdetails?.asyncexecutealltasksnoestiamtioncomplete()
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
}

@available(macOS 14.0, *)
extension ExecuteTasksAsync14 {
    func processterminationexecute(outputfromrsync: [String]?, hiddenID: Int?) {
        // Log records
        // If snahost task the snapshotnum is increased when updating the configuration.
        // When creating the logrecord, decrease the snapshotum by 1
        configrecords.append((hiddenID ?? -1, Date().en_us_string_from_date()))
        schedulerecords.append((hiddenID ?? -1, Numbers(outputfromrsync ?? []).stats()))

        let record = RemoteinfonumbersOnetask(hiddenID: hiddenID,
                                              outputfromrsync: outputfromrsync,
                                              config: localconfigurations?.getconfig(hiddenID: hiddenID ?? -1))
        estimateprogressdetails?.appendrecordestimatedlist(record)
        if let config = localconfigurations?.getconfig(hiddenID: hiddenID ?? -1) {
            estimateprogressdetails?.appenduuid(config.id)
        }
        _ = Task.detached {
            await self.startexecution()
        }
    }
}
