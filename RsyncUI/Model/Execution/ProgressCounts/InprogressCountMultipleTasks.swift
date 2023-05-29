//
//  InprogressCountEstimation.swift
//  RsyncSwiftUI
//
//  Created by Thomas Evensen on 20/01/2021.
//

import Foundation

protocol UpdateEstimationCount: AnyObject {
    func resetcounts()
    func updateinprogresscount(num: Double)
    func setmaxcount(num: Int)
    func setestimatedlist(_ argestimatedlist: [RemoteinfonumbersOnetask]?)
    func getestimatedlist() -> [RemoteinfonumbersOnetask]?
    func sethiddenID(_ arghiddenID: Int)
    func appenduuid(id: UUID)
    func getuuids() -> Set<UUID>
    func appendrecord(record: RemoteinfonumbersOnetask)
    func asyncestimationcomplete()
    func asyncexecutealltasksnoestiamtioncomplete()
    func startasyncexecutealltasksnoestimation()
    func asyncexecutecomplete()

    func setprofileandnumberofconfigurations(_ profile: String, _ num: Int)
    func alltasksestimated(_ profilename: String) -> Bool
    func getprofile() -> String
}

final class InprogressCountMultipleTasks: ObservableObject, UpdateEstimationCount {
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

    private var estimatedlist: [RemoteinfonumbersOnetask]?
    private var inprogresscount: Double = 0
    private var max: Int = 0
    // Which hiddenID is in estimation
    var hiddenID: Int = -1
    // set uuid if data to be transferred
    private var uuids = Set<UUID>()
    // Estimate async
    var estimateasync: Bool = false
    var executeasyncnoestimationcompleted: Bool = false
    // Profilename and timestamp start estimation
    private var profile: String?
    private var timestamp: Date?
    private var numberofconfigurations: Int = -1

    func getuuids() -> Set<UUID> {
        return uuids
    }

    func appenduuid(id: UUID) {
        uuids.insert(id)
        // objectWillChange.send()
    }

    // Set and notify when new hiddenID is set
    func sethiddenID(_ arghiddenID: Int) {
        hiddenID = arghiddenID
        objectWillChange.send()
    }

    func resetcounts() {
        hiddenID = -1
        numberofconfigurations = -1
        inprogresscount = 0
        max = 0
        uuids.removeAll()
        estimatedlist = nil
        timestamp = Date()
        profile = nil
    }

    func getinprogress() -> Double {
        return inprogresscount
    }

    func setmaxcount(num: Int) {
        max = num
    }

    func updateinprogresscount(num: Double) {
        inprogresscount = num
        objectWillChange.send()
    }

    func setestimatedlist(_ argestimatedlist: [RemoteinfonumbersOnetask]?) {
        estimatedlist = argestimatedlist
    }

    func appendrecord(record: RemoteinfonumbersOnetask) {
        if estimatedlist == nil {
            estimatedlist = [RemoteinfonumbersOnetask]()
        }
        estimatedlist?.append(record)
    }

    func asyncestimationcomplete() {
        estimateasync = false
        objectWillChange.send()
    }

    func asyncexecutecomplete() {
        executeasyncnoestimationcompleted = true
        objectWillChange.send()
    }

    func startestimateasync() {
        estimateasync = true
        objectWillChange.send()
    }

    func asyncexecutealltasksnoestiamtioncomplete() {
        executeasyncnoestimationcompleted = true
        objectWillChange.send()
    }

    func startasyncexecutealltasksnoestimation() {
        executeasyncnoestimationcompleted = false
        objectWillChange.send()
    }

    func getestimatedlist() -> [RemoteinfonumbersOnetask]? {
        return estimatedlist
    }

    deinit {
        // print("deinit InprogressCountMultipleTasks")
    }
}
