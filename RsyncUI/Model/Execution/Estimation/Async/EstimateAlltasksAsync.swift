//
//  EstimateAlltasksAsync.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 20/10/2022.
//

import Foundation

final class EstimateAlltasksAsync {
    private var localconfigurationsSwiftUI: ConfigurationsSwiftUI?
    private var estimationonetask: EstimationOnetaskAsync?
    private var stackoftasktobeestimated: [Int]?
    weak var updateestimationcountDelegate: UpdateEstimationCount?

    private func prepareandstartexecutetasks(_ configurations: [Configuration]?) {
        stackoftasktobeestimated = [Int]()
        for i in 0 ..< (configurations?.count ?? 0) {
            let task = configurations?[i].task
            if SharedReference.shared.synctasks.contains(task ?? "") {
                if let hiddenID = configurations?[i].hiddenID {
                    stackoftasktobeestimated?.append(hiddenID)
                }
            }
        }
        updateestimationcountDelegate?.setmaxcount(num: stackoftasktobeestimated?.count ?? 0)
    }

    @MainActor
    func startestimation() async {
        let localhiddenID = stackoftasktobeestimated?.removeLast()
        guard localhiddenID != nil else { return }
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
         filter: String)
    {
        localconfigurationsSwiftUI = configurationsSwiftUI
        updateestimationcountDelegate = updateinprogresscount
        // local is true for getting info about local catalogs.
        // used when shwoing diff local files vs remote files

        let filteredconfigurations = configurationsSwiftUI?.getallconfigurations()?.filter { filter.isEmpty ? true : $0.backupID.contains(filter) }
        prepareandstartexecutetasks(filteredconfigurations)
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

        let task = Task.detached {
            await self.startestimation()
        }
    }
}
