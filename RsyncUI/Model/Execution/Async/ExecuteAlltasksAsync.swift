//
//  ExecuteAlltasksAsync.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 22/10/2022.
//

import Foundation

final class ExecuteAlltasksAsync: EstimateAlltasksAsync {
    @MainActor
    override func startestimation() async {
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
        if Int(record.transferredNumber) ?? 0 > 0 || Int(record.deletefiles) ?? 0 > 0 {
            if let config = getconfig(hiddenID: hiddenID) {
                updateestimationcountDelegate?.appenduuid(id: config.id)
            }
        }
        _ = Logfile(TrimTwo(outputfromrsync ?? []).trimmeddata, error: false)
        _ = Task.detached {
            await self.startestimation()
        }
    }
}
