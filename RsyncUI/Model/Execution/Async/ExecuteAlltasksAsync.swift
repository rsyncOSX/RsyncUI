//
//  ExecuteAlltasksAsync.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 22/10/2022.
//
// swiftlint:disable line_length

import Foundation

final class ExecuteAlltasksAsync: EstimateTasksAsync {
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
            estimatingprogresscountDelegate?.asyncexecutealltasksnoestiamtioncomplete()
            return
        }
        let localhiddenID = stackoftasktobeestimated?.removeLast()
        guard localhiddenID != nil else { return }
        if let config = localconfigurations?.getconfiguration(hiddenID: localhiddenID ?? 0) {
            let arguments = Argumentsforrsync().argumentsforrsync(config: config, argtype: .arg)
            guard arguments.count > 0 else { return }
            let process = RsyncProcessAsync(arguments: arguments,
                                            config: config,
                                            processtermination: processterminationexecute)
            await process.executeProcess()
        }
    }
}

extension ExecuteAlltasksAsync {
    func processterminationexecute(outputfromrsync: [String]?, hiddenID: Int?) {
        // Log records
        // If snahost task the snapshotnum is increased when updating the configuration.
        // When creating the logrecord, decrease the snapshotum by 1
        configrecords.append((hiddenID ?? -1, Date().en_us_string_from_date()))
        schedulerecords.append((hiddenID ?? -1, Numbers(outputfromrsync ?? []).stats()))

        let record = RemoteinfonumbersOnetask(hiddenID: hiddenID,
                                              outputfromrsync: outputfromrsync,
                                              config: getconfig(hiddenID: hiddenID))
        estimatingprogresscountDelegate?.appendrecordestimatedlist(record)
        if let config = getconfig(hiddenID: hiddenID) {
            estimatingprogresscountDelegate?.appenduuid(config.id)
        }
        _ = Task.detached {
            await self.startexecution()
        }
    }
}
