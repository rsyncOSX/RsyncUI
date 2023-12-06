//
//  ExecuteProgressDetails.swift
//  RsyncSwiftUI
//
//  Created by Thomas Evensen on 18/02/2021.
//

import Foundation

final class ExecuteProgressDetails: ObservableObject {
    @Published var executeasyncnoestimationcompleted: Bool = false
    // Value for storing progress for current task in work
    var currenttaskprogress: Double = 0
    var hiddenIDatwork: Int = -1
    var estimatedlist: [RemoteDataNumbers]?

    // set uuid if data to be transferred
    var uuids = Set<UUID>()
    var max: Int = 0
    // Profilename and timestamp start estimation
    var profile: String?
    var numberofconfigurations: Int = -1

    func taskisestimatedbyUUID(_ uuid: UUID) -> Bool {
        let answer = estimatedlist?.contains(where: { task in
            task.id == uuid
        }) ?? false ? true : false
        return answer
    }

    func setcurrentprogress(_ num: Double) {
        currenttaskprogress = num
        objectWillChange.send()
    }

    func getmaxcountbytask() -> Double {
        let max = estimatedlist?.filter { $0.hiddenID == hiddenIDatwork }
        if (max?.count ?? 0) == 1 {
            return Double(max?[0].outputfromrsync?.count ?? 0)
        } else {
            return 0
        }
    }

    func setestimatedlist(_ argestimatedlist: [RemoteDataNumbers]?) {
        estimatedlist = argestimatedlist
    }

    func resetcounts() {
        currenttaskprogress = 0
        estimatedlist = nil
        numberofconfigurations = -1
        max = 0
        uuids.removeAll()
        profile = nil
        uuids.removeAll()
    }

    func asyncexecutealltasksnoestiamtioncomplete() {
        executeasyncnoestimationcompleted = true
    }

    func startasyncexecutealltasksnoestimation() {
        executeasyncnoestimationcompleted = false
    }

    func appendrecordexecutedlist(_ record: RemoteDataNumbers) {
        if estimatedlist == nil {
            estimatedlist = [RemoteDataNumbers]()
        }
        estimatedlist?.append(record)
    }

    func appenduuid(_ id: UUID) {
        uuids.insert(id)
    }

    func setmaxcount(_ num: Int) {
        max = num
    }

    func setprofileandnumberofconfigurations(_ profilename: String, _ num: Int) {
        profile = profilename
        numberofconfigurations = num
    }

    deinit {
        // print("deinit ProgressDetails")
    }
}
