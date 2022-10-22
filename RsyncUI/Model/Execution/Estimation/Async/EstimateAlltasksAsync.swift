//
//  EstimateAlltasksAsync.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 20/10/2022.
//

import Foundation

class EstimateAlltasksAsync {
    var localconfigurationsSwiftUI: ConfigurationsSwiftUI?
    var estimationonetask: EstimateOnetaskAsync?
    var stackoftasktobeestimated: [Int]?
    weak var updateestimationcountDelegate: UpdateEstimationCount?

    @MainActor
    func startestimation() async {
        guard stackoftasktobeestimated?.count ?? 0 > 0 else {
            updateestimationcountDelegate?.asyncestimationcomplete()
            return
        }
        let localhiddenID = stackoftasktobeestimated?.removeLast()
        guard localhiddenID != nil else { return }
        let arguments = localconfigurationsSwiftUI?.arguments4rsync(hiddenID: localhiddenID ?? 0, argtype: .argdryRun)
        let config = localconfigurationsSwiftUI?.getconfiguration(hiddenID: localhiddenID ?? 0)
        guard arguments?.count ?? 0 > 0 else { return }
        let process = RsyncProcessAsync(arguments: arguments,
                                        config: config,
                                        processtermination: processtermination,
                                        newlineisread: newlineisread)
        await process.executeProcess()
    }

    init(configurationsSwiftUI: ConfigurationsSwiftUI?,
         updateinprogresscount: UpdateEstimationCount?,
         uuids: Set<UUID>,
         filter: String)
    {
        localconfigurationsSwiftUI = configurationsSwiftUI
        updateestimationcountDelegate = updateinprogresscount
        let filteredconfigurations = configurationsSwiftUI?.getallconfigurations()?.filter { filter.isEmpty ? true : $0.backupID.contains(filter) }
        stackoftasktobeestimated = [Int]()
        // Estimate selected configurations
        if uuids.count > 0 {
            let configurations = filteredconfigurations?.filter { uuids.contains($0.id) }
            for i in 0 ..< (configurations?.count ?? 0) {
                if let hiddenID = configurations?[i].hiddenID {
                    stackoftasktobeestimated?.append(hiddenID)
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
        updateestimationcountDelegate?.setmaxcount(num: stackoftasktobeestimated?.count ?? 0)
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

extension EstimateAlltasksAsync {
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
        _ = Task.detached {
            await self.startestimation()
        }
    }

    func newlineisread() {}
}
