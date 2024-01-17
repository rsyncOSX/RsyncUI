//
//  EstimateAlltasksAsync.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 20/10/2022.
//
// swiftlint: disable line_length

import Foundation

class EstimateTasksAsync {
    var structprofile: String?
    var localconfigurations: RsyncUIconfigurations?
    var stackoftasktobeestimated: [Int]?
    weak var localestimateprogressdetails: EstimateProgressDetails?

    @MainActor
    func startestimation() async {
        guard stackoftasktobeestimated?.count ?? 0 > 0 else {
            localestimateprogressdetails?.asyncestimationcomplete()
            return
        }
        let localhiddenID = stackoftasktobeestimated?.removeLast()
        guard localhiddenID != nil else { return }
        if let config = localconfigurations?.getconfig(hiddenID: localhiddenID ?? 0) {
            let arguments = Argumentsforrsync().argumentsforrsync(config: config, argtype: .argdryRun)
            guard arguments.count > 0 else { return }
            // Used to display details of configuration in estimation
            localestimateprogressdetails?.configurationtobestimated = config.id
            let process = RsyncProcessAsync(arguments: arguments,
                                            config: config,
                                            processtermination: processtermination)
            await process.executeProcess()
        }
    }

    init(profile: String?,
         configurations: RsyncUIconfigurations?,
         estimateprogressdetails: EstimateProgressDetails?,
         uuids: Set<UUID>,
         filter: String)
    {
        structprofile = profile
        localconfigurations = configurations
        localestimateprogressdetails = estimateprogressdetails
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
        localestimateprogressdetails?.setprofileandnumberofconfigurations(structprofile ?? "Default profile", localconfigurations?.getallconfigurations()?.count ?? 0)
    }
}

extension EstimateTasksAsync {
    func processtermination(outputfromrsync: [String]?, hiddenID: Int?) {
        let record = RemoteDataNumbers(hiddenID: hiddenID,
                                       outputfromrsync: outputfromrsync,
                                       config: localconfigurations?.getconfig(hiddenID: hiddenID ?? -1))
        localestimateprogressdetails?.appendrecordestimatedlist(record)
        if Int(record.transferredNumber) ?? 0 > 0 || Int(record.deletefiles) ?? 0 > 0 {
            if let config = localconfigurations?.getconfig(hiddenID: hiddenID ?? -1) {
                localestimateprogressdetails?.appenduuid(config.id)
            }
        }

        Task {
            await self.startestimation()
        }
    }
}

// swiftlint: enable line_length
