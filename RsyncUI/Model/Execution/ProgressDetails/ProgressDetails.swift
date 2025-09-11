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

    // For execution
    var hiddenIDatwork: Int = -1

    func getmaxcountbytask() -> Double {
        let max = estimatedlist?.filter { $0.hiddenID == hiddenIDatwork }
        if (max?.count ?? 0) == 1 {
            var num = 0.0
            if SharedReference.shared.rsyncversion3 {
                // Reduce count with 16 last rows which contains summarized status from rsync
                num = Double(max?[0].outputfromrsync?.count ?? 0) - 16
                if num <= 0 {
                    num = 0
                    Logger.process.warning("ProgressDetails: EXECUTING getmaxcountbytask() num = 0")
                }
                Logger.process.info("ProgressDetails: EXECUTING getmaxcountbytask() count: \(num, privacy: .public)")
                return num
            } else {
                num = Double(max?[0].outputfromrsync?.count ?? 0)
                if num <= 0 {
                    num = 0
                    Logger.process.warning("ProgressDetails: EXECUTING getmaxcountbytask() num = 0")
                }
                Logger.process.info("ProgressDetails: EXECUTING getmaxcountbytask() count: \(num, privacy: .public)")
                return num
            }
        } else {
            return 0
        }
    }

    // For execution

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

    func setprofileandnumberofconfigurations(_ profilename: String?, _ num: Int) {
        profile = profilename
        numberofconfigurations = num
    }

    func executeanotherdryrun(_ profilename: String?) -> Bool {
        estimatealltasksinprogress == false &&
            onetaskisestimated == true &&
            estimatedlist?.count != numberofconfigurations &&
            profile == profilename
    }

    func alltasksestimated(_ profilename: String?) -> Bool {
        estimatealltasksinprogress == false &&
            estimatedlist?.count == numberofconfigurations &&
            profile == profilename
    }

    func getuuidswithdatatosynchronize() -> Set<UUID> {
        uuidswithdatatosynchronize
    }

    func appenduuidwithdatatosynchronize(_ id: UUID) {
        Logger.process.info("ProgressDetails: ESTIMATION appending uuid \(id) to uuidswithdatatosynchronize")
        uuidswithdatatosynchronize.insert(id)
    }

    func resetcounts() {
        Logger.process.info("ProgressDetails: RESET all properties")
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
        let numbers = estimatedlist?.count ?? 0
        Logger.process.info("ProgressDetails: ESTIMATION appendrecordestimatedlist - count: \(numbers, privacy: .public)")
    }

    func estimationiscomplete() {
        estimatealltasksinprogress = false
        let numbers = estimatedlist?.count ?? 0
        Logger.process.info("ProgressDetails: ESTIMATION completed: \(numbers, privacy: .public)")
    }

    func startestimation() {
        estimatealltasksinprogress = true
        Logger.process.info("ProgressDetails: ESTIMATION started")
    }

    func confirmexecutetasks() -> Bool {
        let filterconfirm = estimatedlist?.filter { $0.confirmexecute == true }
        return filterconfirm?.count ?? 0 > 0
    }

    init() {
        Logger.process.info("ProgressDetails INIT")
    }
}
