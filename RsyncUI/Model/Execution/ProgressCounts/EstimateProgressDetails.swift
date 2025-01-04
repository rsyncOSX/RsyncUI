//
//  EstimateProgressDetails.swift
//  RsyncSwiftUI
//
//  Created by Thomas Evensen on 20/01/2021.
//

import Foundation
import Observation
import OSLog

@Observable
final class EstimateProgressDetails {
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

    func tasksareestimated(_ uuids: Set<UUID>) -> Bool {
        let answer = estimatedlist?.filter {
            uuids.contains($0.id)
        }
        return answer?.count == uuids.count
    }

    func onlyselectedtaskisestimated(_ uuids: Set<UUID>) -> Bool {
        let answer = estimatedlist?.filter {
            uuids.contains($0.id)
        }
        return (answer?.count ?? 0 == 1) && (estimatedlist?.count ?? 0 == 1)
    }

    func setprofileandnumberofconfigurations(_ profilename: String, _ num: Int) {
        profile = profilename
        numberofconfigurations = num
    }

    func executeanotherdryrun(_ profilename: String) -> Bool {
        estimatealltasksinprogress == false &&
            onetaskisestimated == true &&
            estimatedlist?.count != numberofconfigurations &&
            profile == profilename
    }

    func alltasksestimated(_ profilename: String) -> Bool {
        estimatealltasksinprogress == false &&
            estimatedlist?.count == numberofconfigurations &&
            profile == profilename
    }

    func getuuidswithdatatosynchronize() -> Set<UUID> {
        uuidswithdatatosynchronize
    }

    func appenduuidwithdatatosynchronize(_ id: UUID) {
        uuidswithdatatosynchronize.insert(id)
    }

    func resetcounts() {
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

    func appendrecordestimatedlist(_ record: RemoteDataNumbers) {
        if estimatedlist == nil {
            estimatedlist = [RemoteDataNumbers]()
        }
        estimatedlist?.append(record)
        numberofconfigurationsestimated = Double(estimatedlist?.count ?? 0)
        onetaskisestimated = true
    }

    func estimationiscomplete() {
        estimatealltasksinprogress = false
        Logger.process.info("EstimateProgressDetails: estimation COMPLETED")
    }

    func startestimation() {
        estimatealltasksinprogress = true
        Logger.process.info("EstimateProgressDetails: estimation STARTED")
    }

    func confirmexecutetasks() -> Bool {
        let filterconfirm = estimatedlist?.filter { $0.confirmsynchronize == true }
        return filterconfirm?.count ?? 0 > 0
    }
}
