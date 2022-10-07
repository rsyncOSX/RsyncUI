//
//  EstimationAsync.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 04/10/2022.
//

import Foundation

final class EstimationAsync {
    private var localconfigurationsSwiftUI: ConfigurationsSwiftUI?
    private var estimationonetask: EstimationOnetaskAsync?
    private var localhiddenID: Int = 0

    weak var stateDelegate: EstimationState?
    weak var updateestimationcountDelegate: UpdateEstimationCount?

    @MainActor
    func startestimation() async {
        stateDelegate?.updatestate(state: .start)
        print(localhiddenID)
        updateestimationcountDelegate?.sethiddenID(localhiddenID)
        estimationonetask = EstimationOnetaskAsync(hiddenID: localhiddenID,
                                                   configurationsSwiftUI: localconfigurationsSwiftUI,
                                                   local: false,
                                                   processtermination: processtermination)
        await estimationonetask?.startestimation()
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

    init(configurationsSwiftUI: ConfigurationsSwiftUI?,
         estimationstateDelegate: EstimationState?,
         updateinprogresscount: UpdateEstimationCount?,
         hiddenID: Int)
    {
        localconfigurationsSwiftUI = configurationsSwiftUI
        stateDelegate = estimationstateDelegate
        updateestimationcountDelegate = updateinprogresscount
        localhiddenID = hiddenID
    }

    deinit {
        // print("deinit Estimation")
    }

    func abort() {
        estimationonetask = nil
        updateestimationcountDelegate?.resetcounts()
    }
}

extension EstimationAsync {
    func processtermination(outputfromrsync: [String]?, hiddenID: Int?) {
        // Release the estimation object
        estimationonetask = nil
        // updateestimationcountDelegate?.updateinprogresscount(num: Double((max ?? 0) - (stackoftasktobeestimated?.count ?? 0)))
        let record = RemoteinfonumbersOnetask(hiddenID: hiddenID,
                                              outputfromrsync: outputfromrsync,
                                              config: getconfig(hiddenID: hiddenID))
        updateestimationcountDelegate?.appendrecord(record: record)
        if Int(record.transferredNumber) ?? 0 > 0 || Int(record.deletefiles) ?? 0 > 0 {
            if let config = getconfig(hiddenID: hiddenID) {
                updateestimationcountDelegate?.appenduuid(id: config.id)
            }
        }
    }
}
