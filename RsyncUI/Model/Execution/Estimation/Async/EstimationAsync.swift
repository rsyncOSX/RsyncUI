//
//  EstimationAsync.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 04/10/2022.
//

import Foundation

final class EstimationAsync {
    private var localconfigurationsSwiftUI: ConfigurationsSwiftUI?
    // private var privatehiddenID: Int?
    private var stackoftasktobeestimated: [Int]?
    private var max: Int?
    private var hiddenIDs: [Int]?
    private var estimationonetask: EstimationOnetaskAsync?
    // Set if abort is executed
    private var setabort = false

    weak var stateDelegate: EstimationState?
    weak var updateestimationcountDelegate: UpdateEstimationCount?

    private func prepareandstartexecutetasks(_ configurations: [Configuration]?) {
        stackoftasktobeestimated = [Int]()
        // Multiple selected indexes
        if let hiddenIDs = hiddenIDs {
            for i in 0 ..< hiddenIDs.count {
                stackoftasktobeestimated?.append(hiddenIDs[i])
            }
            // Estimate all or filtered tasks
        } else {
            for i in 0 ..< (configurations?.count ?? 0) {
                let task = configurations?[i].task
                if SharedReference.shared.synctasks.contains(task ?? "") {
                    if let hiddenID = configurations?[i].hiddenID {
                        stackoftasktobeestimated?.append(hiddenID)
                    }
                }
            }
        }
        max = stackoftasktobeestimated?.count
        updateestimationcountDelegate?.setmaxcount(num: stackoftasktobeestimated?.count ?? 0)
    }

    @MainActor
    func startestimation() async {
        guard (stackoftasktobeestimated?.count ?? 0) > 0 else { return }
        stateDelegate?.updatestate(state: .start)
        if let hiddenID = stackoftasktobeestimated?.remove(at: 0) {
            print(hiddenID)
            updateestimationcountDelegate?.sethiddenID(hiddenID)
            estimationonetask = EstimationOnetaskAsync(hiddenID: hiddenID,
                                                       configurationsSwiftUI: localconfigurationsSwiftUI,
                                                       local: false,
                                                       processtermination: processtermination)
            await estimationonetask?.startestimation()
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

    init(configurationsSwiftUI: ConfigurationsSwiftUI?,
         estimationstateDelegate: EstimationState?,
         updateinprogresscount: UpdateEstimationCount?,
         uuids: Set<UUID>,
         filter: String)
    {
        localconfigurationsSwiftUI = configurationsSwiftUI
        stateDelegate = estimationstateDelegate
        updateestimationcountDelegate = updateinprogresscount
        let filteredconfigurations = configurationsSwiftUI?.getallconfigurations()?.filter { filter.isEmpty ? true : $0.backupID.contains(filter) }
        if uuids.count > 0 {
            // Estimate selected configurations
            hiddenIDs = [Int]()
            let configurations = filteredconfigurations?.filter { uuids.contains($0.id) }
            for i in 0 ..< (configurations?.count ?? 0) {
                if let hiddenID = configurations?[i].hiddenID {
                    hiddenIDs?.append(hiddenID)
                }
            }
            // Clearing old selected uuids not done, must fix
            if (configurations?.count ?? 0) == 0 {
                hiddenIDs = nil
            }
        } else {
            // Estimate all configurations
            hiddenIDs = nil
        }
        prepareandstartexecutetasks(filteredconfigurations)
    }

    deinit {
        self.stackoftasktobeestimated = nil
        // print("deinit Estimation")
    }

    func abort() {
        stackoftasktobeestimated = nil
        estimationonetask = nil
        updateestimationcountDelegate?.resetcounts()
        setabort = true
    }
}

extension EstimationAsync {
    func processtermination(outputfromrsync: [String]?, hiddenID: Int?) {
        // Release the estimation object
        estimationonetask = nil
        guard setabort == false else { return }
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
