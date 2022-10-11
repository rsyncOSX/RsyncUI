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
    func getmaxcount() -> Int
    func setmaxcount(num: Int)
    func setestimatedlist(_ argestimatedlist: [RemoteinfonumbersOnetask]?)
    func getestimatedlist() -> [RemoteinfonumbersOnetask]?
    func sethiddenID(_ arghiddenID: Int)
    func appenduuid(id: UUID)
    func getuuids() -> Set<UUID>
    func appendrecord(record: RemoteinfonumbersOnetask)
}

final class InprogressCountMultipleTasks: ObservableObject, UpdateEstimationCount {
    private var estimatedlist: [RemoteinfonumbersOnetask]?
    private var inprogresscount: Double = 0
    private var max: Int = 0
    // Which hiddenID is in estimation
    var hiddenID: Int = -1
    // set uuid if data to be transferred
    private var uuids = Set<UUID>()
    // Estimate async
    var estimateasync: Bool = false

    func getuuids() -> Set<UUID> {
        return uuids
    }

    func appenduuid(id: UUID) {
        uuids.insert(id)
        objectWillChange.send()
    }

    // Set and notify when new hiddenID is set
    func sethiddenID(_ arghiddenID: Int) {
        hiddenID = arghiddenID
        objectWillChange.send()
    }

    func resetcounts() {
        hiddenID = -1
        inprogresscount = 0
        max = 0
        uuids.removeAll()
        estimatedlist = nil
    }

    func getmaxcount() -> Int {
        return max
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
        estimateasync = false
        objectWillChange.send()
    }

    func startestimateasync() {
        estimateasync = true
        objectWillChange.send()
    }

    func getestimatedlist() -> [RemoteinfonumbersOnetask]? {
        return estimatedlist
    }

    deinit {
        // print("deinit InprogressCountMultipleTasks")
    }
}
