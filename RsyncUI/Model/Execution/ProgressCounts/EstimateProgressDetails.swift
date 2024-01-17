//
//  EstimateProgressDetails.swift
//  RsyncSwiftUI
//
//  Created by Thomas Evensen on 20/01/2021.
//

import Foundation
import Observation

@Observable
final class EstimateProgressDetails {
    var estimatedlist: [RemoteDataNumbers]?
    // set uuid if data to be transferred
    var uuids = Set<UUID>()
    // Estimate async
    var estimatealltasksasync: Bool = false
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

    func getprofile() -> String {
        return profile ?? "Default profile"
    }

    func setprofileandnumberofconfigurations(_ profilename: String, _ num: Int) {
        profile = profilename
        numberofconfigurations = num
    }

    func executeanotherdryrun(_ profilename: String) -> Bool {
        return estimatealltasksasync == false &&
            onetaskisestimated == true &&
            estimatedlist?.count != numberofconfigurations &&
            profile == profilename
    }

    func alltasksestimated(_ profilename: String) -> Bool {
        return estimatealltasksasync == false &&
            estimatedlist?.count == numberofconfigurations &&
            profile == profilename
    }

    func getuuids() -> Set<UUID> {
        return uuids
    }

    func appenduuid(_ id: UUID) {
        uuids.insert(id)
    }

    func resetcounts() {
        numberofconfigurations = -1
        uuids.removeAll()
        estimatedlist = nil
        profile = nil
        onetaskisestimated = false
        estimatealltasksasync = false
        numberofconfigurations = 0
        numberofconfigurationsestimated = 0
        configurationtobestimated = nil
    }

    func setestimatedlist(_ argestimatedlist: [RemoteDataNumbers]?) {
        estimatedlist = argestimatedlist
    }

    func appendrecordestimatedlist(_ record: RemoteDataNumbers) {
        if estimatedlist == nil {
            estimatedlist = [RemoteDataNumbers]()
        }
        estimatedlist?.append(record)
        numberofconfigurationsestimated = Double(estimatedlist?.count ?? 0)
        onetaskisestimated = true
    }

    func asyncestimationcomplete() {
        estimatealltasksasync = false
    }

    func startestimateasync() {
        estimatealltasksasync = true
    }

    func getestimatedlist() -> [RemoteDataNumbers]? {
        return estimatedlist
    }

    func confirmexecutetasks() -> Bool {
        let filterconfirm = estimatedlist?.filter { $0.confirmsynchronize == true }
        return filterconfirm?.count ?? 0 > 0
    }
}
