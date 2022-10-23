//
//  EstimateOnetaskAsync.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 04/10/2022.
//

import Foundation

class EstimateOnetaskAsync {
    var localconfigurationsSwiftUI: ConfigurationsSwiftUI?
    var estimationonetask: EstimateOnetaskAsync?
    var localhiddenID: Int?
    weak var updateestimationcountDelegate: UpdateEstimationCount?

    @MainActor
    func execute() async {
        let arguments = localconfigurationsSwiftUI?.arguments4rsync(hiddenID: localhiddenID ?? 0, argtype: .argdryRun)
        let config = localconfigurationsSwiftUI?.getconfiguration(hiddenID: localhiddenID ?? 0)
        guard arguments?.count ?? 0 > 0 else { return }
        let process = RsyncProcessAsync(arguments: arguments,
                                        config: config,
                                        processtermination: processtermination)
        await process.executeProcess()
    }

    init(configurationsSwiftUI: ConfigurationsSwiftUI?,
         updateinprogresscount: UpdateEstimationCount?,
         hiddenID: Int?)
    {
        localconfigurationsSwiftUI = configurationsSwiftUI
        updateestimationcountDelegate = updateinprogresscount
        localhiddenID = hiddenID
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

    func newlineisread() {}
}
