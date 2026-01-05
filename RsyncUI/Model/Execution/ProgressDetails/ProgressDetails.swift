//
//  ProgressDetails.swift
//  RsyncSwiftUI
//
//  Created by Thomas Evensen on 20/01/2021.
//

import Foundation
import Observation
import OSLog

@Observable @MainActor
final class ProgressDetails {
    var estimatedlist: [RemoteDataNumbers]?
    // UUIDs with data to be transferred
    var uuidswithdatatosynchronize = Set<UUID>()
    // Estimate
    var estimatealltasksinprogress: Bool = false
    // Estimate on task, same profile
    // If one task in profile is estimated, this is set true
    // Used to decide if new profile is selected.
    // The estiamed list is used for progress if executing.
    var onetaskisestimated: Bool = false
    // Profilename and timestamp start estimation
    var profile: String?
    var numberofconfigurations: Int = 0
    var numberofconfigurationsestimated: Double = 0
    // UUID for configuration to be estimated
    var configurationtobestimated: UUID?

    let reduceestimatedcountV3: Double = 15
    let reduceestimatedcountopenrsync: Double = 13

    // For execution
    var hiddenIDatwork: Int = -1

    func getMaxCountByTask() -> Double {
        let max = estimatedlist?.filter { $0.hiddenID == hiddenIDatwork }
        if (max?.count ?? 0) == 1 {
            var num = 0.0
            if SharedReference.shared.rsyncversion3 {
                // Reduce count with 16 last rows which contains summarized status from rsync
                num = Double(max?[0].outputfromrsync?.count ?? 0) - reduceestimatedcountV3
                if num <= 0 { num = 0 }
                Logger.process.debugMessageOnly("ProgressDetails: EXECUTING getmaxcountbytask() count: \(num)")
                return num
            } else {
                num = Double(max?[0].outputfromrsync?.count ?? 0) - reduceestimatedcountopenrsync
                if num <= 0 { num = 0 }
                Logger.process.debugMessageOnly("ProgressDetails: EXECUTING getmaxcountbytask() count: \(num)")
                return num
            }
        } else {
            return 0
        }
    }

    // For execution

    func tasksAreEstimated(_ uuids: Set<UUID>) -> Bool {
        let answer = estimatedlist?.filter {
            uuids.contains($0.id)
        }
        return answer?.count == uuids.count
    }

    func onlySelectedTaskIsEstimated(_ uuids: Set<UUID>) -> Bool {
        let answer = estimatedlist?.filter {
            uuids.contains($0.id)
        }
        return (answer?.count ?? 0 == 1) && (estimatedlist?.count ?? 0 == 1)
    }

    func setProfileAndNumberOfConfigurations(_ profilename: String?, _ num: Int) {
        profile = profilename
        numberofconfigurations = num
    }

    func executeAnotherDryRun(_ profilename: String?) -> Bool {
        estimatealltasksinprogress == false &&
            onetaskisestimated == true &&
            estimatedlist?.count != numberofconfigurations &&
            profile == profilename
    }

    func allTasksEstimated(_ profilename: String?) -> Bool {
        estimatealltasksinprogress == false &&
            estimatedlist?.count == numberofconfigurations &&
            profile == profilename
    }

    func getUUIDsWithDataToSynchronize() -> Set<UUID> {
        uuidswithdatatosynchronize
    }

    func appendUUIDWithDataToSynchronize(_ id: UUID) {
        uuidswithdatatosynchronize.insert(id)
    }

    func resetCounts() {
        numberofconfigurations = -1
        uuidswithdatatosynchronize.removeAll()
        estimatedlist = nil
        profile = nil
        onetaskisestimated = false
        estimatealltasksinprogress = false
        numberofconfigurations = 0
        numberofconfigurationsestimated = 0
        configurationtobestimated = nil
    }

    func appendRecordEstimatedList(_ record: RemoteDataNumbers) {
        if estimatedlist == nil {
            estimatedlist = [RemoteDataNumbers]()
        }
        estimatedlist?.append(record)
        numberofconfigurationsestimated = Double(estimatedlist?.count ?? 0)
        onetaskisestimated = true
        let numbers = estimatedlist?.count ?? 0
        Logger.process.debugMessageOnly("ProgressDetails: ESTIMATION appendrecordestimatedlist - count: \(numbers)")
    }

    func estimationIsComplete() {
        estimatealltasksinprogress = false
        let numbers = estimatedlist?.count ?? 0
        Logger.process.debugMessageOnly("ProgressDetails: ESTIMATION completed: \(numbers)")
    }

    func startEstimation() {
        estimatealltasksinprogress = true
        Logger.process.debugMessageOnly("ProgressDetails: ESTIMATION started")
    }

    func confirmExecuteTasks() -> Bool {
        let filterconfirm = estimatedlist?.filter { $0.confirmexecute == true }
        return filterconfirm?.count ?? 0 > 0
    }
}
