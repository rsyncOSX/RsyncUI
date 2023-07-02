//
//  EstimateOnetaskAsync.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 04/10/2022.
//
// swiftlint: disable line_length

import Foundation

class EstimateOnetaskAsync {
    var localconfigurations: RsyncUIconfigurations?
    var localhiddenID: Int?
    weak var updateestimationcountDelegate: UpdateEstimationCount?

    @MainActor
    func execute() async {
        if let config = localconfigurations?.getconfiguration(hiddenID: localhiddenID ?? 0) {
            let arguments = Argumentsforrsync().argumentsforrsync(config: config, argtype: .argdryRun)
            guard arguments.count > 0 else { return }
            let process = RsyncProcessAsync(arguments: arguments,
                                            config: config,
                                            processtermination: processtermination)
            await process.executeProcess()
        }
    }

    init(configurations: RsyncUIconfigurations?,
         updateinprogresscount: UpdateEstimationCount?,
         hiddenID: Int?)
    {
        localconfigurations = configurations
        updateestimationcountDelegate = updateinprogresscount
        localhiddenID = hiddenID
    }

    func getconfig(hiddenID: Int?) -> Configuration? {
        if let hiddenID = hiddenID {
            if let configurations = localconfigurations?.getallconfigurations()?.filter({ $0.hiddenID == hiddenID }) {
                guard configurations.count == 1 else { return nil }
                return configurations[0]
            }
        }
        return nil
    }

    deinit {
        // print("deinit EstimationOnetask")
    }
}

extension EstimateOnetaskAsync {
    func processtermination(outputfromrsync: [String]?, hiddenID: Int?) {
        let record = RemoteinfonumbersOnetask(hiddenID: hiddenID,
                                              outputfromrsync: outputfromrsync,
                                              config: getconfig(hiddenID: hiddenID))
        updateestimationcountDelegate?.appendrecord(record: record)
        if Int(record.transferredNumber) ?? 0 > 0 || Int(record.deletefiles) ?? 0 > 0 {
            if let config = getconfig(hiddenID: hiddenID) {
                updateestimationcountDelegate?.appenduuid(id: config.id)
            }
        }
        updateestimationcountDelegate?.asyncestimationcomplete()
    }
}
