//
//  ExecuteAlltasksAsync.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 22/10/2022.
//

import Foundation

final class ExecuteAlltasksAsync: EstimateAlltasksAsync {
    @MainActor
    override func startexecution() async {
        guard stackoftasktobeestimated?.count ?? 0 > 0 else {
            updateestimationcountDelegate?.asyncexecutealltasksnoestiamtioncomplete()
            return
        }
        let localhiddenID = stackoftasktobeestimated?.removeLast()
        guard localhiddenID != nil else { return }
        let arguments = localconfigurationsSwiftUI?.arguments4rsync(hiddenID: localhiddenID ?? 0, argtype: .arg)
        let config = localconfigurationsSwiftUI?.getconfiguration(hiddenID: localhiddenID ?? 0)
        guard arguments?.count ?? 0 > 0 else { return }
        let process = RsyncProcessAsync(arguments: arguments,
                                        config: config,
                                        processtermination: processterminationexecute)
        await process.executeProcess()
    }
}

extension ExecuteAlltasksAsync {
    func processterminationexecute(outputfromrsync: [String]?, hiddenID: Int?) {
        let record = RemoteinfonumbersOnetask(hiddenID: hiddenID,
                                              outputfromrsync: outputfromrsync,
                                              config: getconfig(hiddenID: hiddenID))
        updateestimationcountDelegate?.appendrecord(record: record)
        if let config = getconfig(hiddenID: hiddenID) {
            updateestimationcountDelegate?.appenduuid(id: config.id)
            let update = SingletaskPrimaryLogging(profile: config.profile,
                                                  hiddenID: hiddenID,
                                                  configurations: localconfigurationsSwiftUI?.getallconfigurations(),
                                                  validhiddenIDs: localconfigurationsSwiftUI?.validhiddenIDs ?? Set())
            update.setCurrentDateonConfiguration()
            update.addlogpermanentstore(outputrsync: outputfromrsync)
        }
        _ = Task.detached {
            await self.startexecution()
        }
    }
}
