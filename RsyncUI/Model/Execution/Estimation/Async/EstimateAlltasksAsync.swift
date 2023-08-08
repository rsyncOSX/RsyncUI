//
//  EstimateAlltasksAsync.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 20/10/2022.
//
// swiftlint: disable line_length

import Foundation

class EstimateAlltasksAsync {
    var structprofile: String?
    var localconfigurations: RsyncUIconfigurations?
    var stackoftasktobeestimated: [Int]?
    weak var estimatingprogresscountDelegate: InprogressCountEstimation?

    @MainActor
    func startexecution() async {
        guard stackoftasktobeestimated?.count ?? 0 > 0 else {
            estimatingprogresscountDelegate?.asyncestimationcomplete()
            return
        }
        let localhiddenID = stackoftasktobeestimated?.removeLast()
        guard localhiddenID != nil else { return }
        if let config = localconfigurations?.getconfiguration(hiddenID: localhiddenID ?? 0) {
            let arguments = Argumentsforrsync().argumentsforrsync(config: config, argtype: .argdryRun)
            guard arguments.count > 0 else { return }
            let process = RsyncProcessAsync(arguments: arguments,
                                            config: config,
                                            processtermination: processtermination)
            await process.executeProcess()
        }
    }

    init(profile: String?,
         configurations: RsyncUIconfigurations?,
         updateinprogresscount: InprogressCountEstimation?,
         uuids: Set<UUID>,
         filter: String)
    {
        structprofile = profile
        localconfigurations = configurations
        estimatingprogresscountDelegate = updateinprogresscount
        let filteredconfigurations = localconfigurations?.getallconfigurations()?.filter { filter.isEmpty ? true : $0.backupID.contains(filter) }
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
        estimatingprogresscountDelegate?.setmaxcount(stackoftasktobeestimated?.count ?? 0)
        estimatingprogresscountDelegate?.setprofileandnumberofconfigurations(structprofile ?? "Default profile", localconfigurations?.getallconfigurations()?.count ?? 0)
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

extension EstimateAlltasksAsync {
    func processtermination(outputfromrsync: [String]?, hiddenID: Int?) {
        let record = RemoteinfonumbersOnetask(hiddenID: hiddenID,
                                              outputfromrsync: outputfromrsync,
                                              config: getconfig(hiddenID: hiddenID))
        estimatingprogresscountDelegate?.appendrecordestimatedlist(record)
        if Int(record.transferredNumber) ?? 0 > 0 || Int(record.deletefiles) ?? 0 > 0 {
            if let config = getconfig(hiddenID: hiddenID) {
                estimatingprogresscountDelegate?.appenduuid(config.id)
            }
        }
        _ = Task.detached {
            await self.startexecution()
        }
    }
}
