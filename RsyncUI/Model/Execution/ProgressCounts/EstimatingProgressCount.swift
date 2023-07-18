//
//  InprogressCountEstimation.swift
//  RsyncSwiftUI
//
//  Created by Thomas Evensen on 20/01/2021.
//

import Foundation
import Observation

@Observable
final class EstimatingProgressCount {
    var estimatedlist: [RemoteinfonumbersOnetask]?
    var tasknumbercount: Double = 0
    var max: Int = 0
    // Which hiddenID is in estimation
    var hiddenID: Int = -1
    // set uuid if data to be transferred
    var uuids = Set<UUID>()
    // Estimate async
    var estimateasync: Bool = false
    var executeasyncnoestimationcompleted: Bool = false
    // Profilename and timestamp start estimation
    var profile: String?
    var timestamp: Date?
    var numberofconfigurations: Int = -1

    func getprofile() -> String {
        return profile ?? "Default profile"
    }

    func setprofileandnumberofconfigurations(_ profilename: String, _ num: Int) {
        profile = profilename
        numberofconfigurations = num
    }

    func alltasksestimated(_ profilename: String) -> Bool {
        return estimateasync == false && estimatedlist?.count == numberofconfigurations && profile == profilename
    }

    func getuuids() -> Set<UUID> {
        return uuids
    }

    func appenduuid(_ id: UUID) {
        uuids.insert(id)
    }

    func sethiddenID(_ arghiddenID: Int) {
        hiddenID = arghiddenID
    }

    func resetcounts() {
        hiddenID = -1
        numberofconfigurations = -1
        tasknumbercount = 0
        max = 0
        uuids.removeAll()
        estimatedlist = nil
        timestamp = Date()
        profile = nil
    }

    func setmaxcount(_ num: Int) {
        max = num
    }

    func updatetasknumbercount(_ num: Double) {
        tasknumbercount = num
    }

    func setestimatedlist(_ argestimatedlist: [RemoteinfonumbersOnetask]?) {
        estimatedlist = argestimatedlist
    }

    func appendrecord(_ record: RemoteinfonumbersOnetask) {
        if estimatedlist == nil {
            estimatedlist = [RemoteinfonumbersOnetask]()
        }
        estimatedlist?.append(record)
    }

    func asyncestimationcomplete() {
        estimateasync = false
    }

    func asyncexecutecomplete() {
        executeasyncnoestimationcompleted = true
    }

    func startestimateasync() {
        estimateasync = true
    }

    func asyncexecutealltasksnoestiamtioncomplete() {
        executeasyncnoestimationcompleted = true
    }

    func startasyncexecutealltasksnoestimation() {
        executeasyncnoestimationcompleted = false
    }

    func getestimatedlist() -> [RemoteinfonumbersOnetask]? {
        return estimatedlist
    }

    deinit {
        print("deinit EstimatingProgressCount")
    }
}
