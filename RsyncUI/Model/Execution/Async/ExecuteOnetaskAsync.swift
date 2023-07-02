//
//  ExecuteOnetaskAsync.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 22/10/2022.
//

import Foundation

final class ExecuteOnetaskAsync: EstimateOnetaskAsync {
    @MainActor
    override func execute() async {
        if let config = localconfigurationsSwiftUI?.getconfiguration(hiddenID: localhiddenID ?? 0) {
            let arguments = Argumentsforrsync().argumentsforrsync(config: config, argtype: .arg)
            guard arguments.count > 0 else { return }
            let process = RsyncProcessAsync(arguments: arguments,
                                            config: config,
                                            processtermination: processterminationexecute)
            await process.executeProcess()
        }
    }
}

extension ExecuteOnetaskAsync {
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
        updateestimationcountDelegate?.asyncexecutecomplete()
    }
}
