//
//  EstimateTasksAsync14.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 19/11/2023.
//

import Foundation

@available(macOS 14.0, *)
class EstimateTasksAsync14 {
    var structprofile: String?
    var localconfigurations: RsyncUIconfigurations?
    var stackoftasktobeestimated: [Int]?
    weak var estimateprogressdetails: EstimateProgressDetails14?

    @MainActor
    func startexecution() async {
        guard stackoftasktobeestimated?.count ?? 0 > 0 else {
            estimateprogressdetails?.asyncestimationcomplete()
            return
        }
        let localhiddenID = stackoftasktobeestimated?.removeLast()
        guard localhiddenID != nil else { return }
        if let config = localconfigurations?.getconfig(hiddenID: localhiddenID ?? 0) {
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
         updateinprogresscount: EstimateProgressDetails14?,
         uuids: Set<UUID>,
         filter: String)
    {
        structprofile = profile
        localconfigurations = configurations
        estimateprogressdetails = updateinprogresscount
        let filteredconfigurations = localconfigurations?.getallconfigurations()?.filter { filter.isEmpty ? true : $0.backupID.contains(filter) }
        stackoftasktobeestimated = [Int]()
        // Estimate selected configurations
        if uuids.count > 0 {
            let configurations = filteredconfigurations?.filter { uuids.contains($0.id) }
            for i in 0 ..< (configurations?.count ?? 0) {
                let task = configurations?[i].task
                if SharedReference.shared.synctasks.contains(task ?? "") {
                    if let hiddenID = configurations?[i].hiddenID {
                        stackoftasktobeestimated?.append(hiddenID)
                    }
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
        estimateprogressdetails?.setmaxcount(stackoftasktobeestimated?.count ?? 0)
        estimateprogressdetails?.setprofileandnumberofconfigurations(structprofile ?? "Default profile", localconfigurations?.getallconfigurations()?.count ?? 0)
    }

    deinit {
        // print("deinit EstimationOnetask")
    }
}

@available(macOS 14.0, *)
extension EstimateTasksAsync14 {
    func processtermination(outputfromrsync: [String]?, hiddenID: Int?) {
        let record = RemoteinfonumbersOnetask(hiddenID: hiddenID,
                                              outputfromrsync: outputfromrsync,
                                              config: localconfigurations?.getconfig(hiddenID: hiddenID ?? -1))
        estimateprogressdetails?.appendrecordestimatedlist(record)
        if Int(record.transferredNumber) ?? 0 > 0 || Int(record.deletefiles) ?? 0 > 0 {
            if let config = localconfigurations?.getconfig(hiddenID: hiddenID ?? -1) {
                estimateprogressdetails?.appenduuid(config.id)
            }
        }
        _ = Task.detached {
            await self.startexecution()
        }
    }
}

// swiftlint: enable line_length