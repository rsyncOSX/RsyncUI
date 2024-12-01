//
//  EstimateTasks.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 20/10/2022.
//
// swiftlint: disable line_length

import Foundation
import OSLog

@MainActor
final class EstimateTasks {
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

    func startestimation() {
        guard stackoftasktobeestimated?.count ?? 0 > 0 else {
            localestimateprogressdetails?.estimationcomplete()
            return
        }
        let localhiddenID = stackoftasktobeestimated?.removeFirst()
        guard localhiddenID != nil else { return }
        if let config = getconfig(localhiddenID ?? -1) {
            if let arguments = ArgumentsSynchronize(config: config).argumentssynchronize(dryRun: true,
                                                                                         forDisplay: false)
            {
                guard arguments.count > 0 else { return }
                // Used to display details of configuration in estimation
                localestimateprogressdetails?.configurationtobestimated = config.id
                let process = ProcessRsync(arguments: arguments,
                                           config: config,
                                           processtermination: processtermination)
                process.executeProcess()
            }
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
        Logger.process.info("EstimateTasks.init: on main thread: \(Thread.isMain)")
        let filteredconfigurations = localconfigurations.filter { filter.isEmpty ? true : $0.backupID.contains(filter) }
        // Estimate selected configurations
        if uuids.count > 0 {
            let configurations = filteredconfigurations.filter { uuids.contains($0.id) }
            stackoftasktobeestimated = configurations.map(\.hiddenID)
        } else {
            // Or estimate all tasks
            stackoftasktobeestimated = filteredconfigurations.map(\.hiddenID)
        }
        localestimateprogressdetails?.setprofileandnumberofconfigurations(structprofile ?? "Default profile", localconfigurations.count)
    }
}

extension EstimateTasks {
    func processtermination(stringoutputfromrsync: [String]?, hiddenID: Int?) {
        let record = RemoteDataNumbers(stringoutputfromrsync: stringoutputfromrsync,
                                       config: getconfig(hiddenID ?? -1))
        localestimateprogressdetails?.appendrecordestimatedlist(record)
        if Int(record.transferredNumber) ?? 0 > 0 || Int(record.deletefiles) ?? 0 > 0 {
            if let config = getconfig(hiddenID ?? -1) {
                localestimateprogressdetails?.appenduuidwithdatatosynchronize(config.id)
            }
        }
        startestimation()
    }
}

// swiftlint: enable line_length
