//
//  EstimateTasksAsync.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 20/10/2022.
//
// swiftlint: disable line_length

import Foundation

class EstimateTasksAsync: @unchecked Sendable {
    var structprofile: String?
    var localconfigurations: [SynchronizeConfiguration]
    var stackoftasktobeestimated: [Int]?
    weak var localestimateprogressdetails: EstimateProgressDetails?

    func getconfig(_ hiddenID: Int) -> SynchronizeConfiguration? {
        if let index = localconfigurations.firstIndex(where: { $0.hiddenID == hiddenID }) {
            return localconfigurations[index]
        }
        return nil
    }

    @MainActor
    func startestimation() async {
        guard stackoftasktobeestimated?.count ?? 0 > 0 else {
            localestimateprogressdetails?.asyncestimationcomplete()
            return
        }
        let localhiddenID = stackoftasktobeestimated?.removeLast()
        guard localhiddenID != nil else { return }
        if let config = getconfig(localhiddenID ?? -1) {
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
         configurations: [SynchronizeConfiguration],
         estimateprogressdetails: EstimateProgressDetails?,
         uuids: Set<UUID>,
         filter: String)
    {
        structprofile = profile
        localconfigurations = configurations
        localestimateprogressdetails = estimateprogressdetails
        let filteredconfigurations = localconfigurations.filter { filter.isEmpty ? true : $0.backupID.contains(filter) }
        stackoftasktobeestimated = [Int]()
        // Estimate selected configurations
        if uuids.count > 0 {
            let configurations = filteredconfigurations.filter { uuids.contains($0.id) }
            for i in 0 ..< configurations.count {
                stackoftasktobeestimated?.append(configurations[i].hiddenID)
            }
        } else {
            // Or estimate all tasks
            for i in 0 ..< filteredconfigurations.count {
                stackoftasktobeestimated?.append(filteredconfigurations[i].hiddenID)
            }
        }
        localestimateprogressdetails?.setprofileandnumberofconfigurations(structprofile ?? "Default profile", localconfigurations.count)
    }
}

extension EstimateTasksAsync {
    func processtermination(outputfromrsync: [String]?, hiddenID: Int?) {
        let record = RemoteDataNumbers(hiddenID: hiddenID,
                                       outputfromrsync: outputfromrsync,
                                       config: getconfig(hiddenID ?? -1))
        localestimateprogressdetails?.appendrecordestimatedlist(record)
        if Int(record.transferredNumber) ?? 0 > 0 || Int(record.deletefiles) ?? 0 > 0 {
            if let config = getconfig(hiddenID ?? -1) {
                localestimateprogressdetails?.appenduuid(config.id)
            }
        }

        Task {
            await self.startestimation()
        }
    }
}

// swiftlint: enable line_length
