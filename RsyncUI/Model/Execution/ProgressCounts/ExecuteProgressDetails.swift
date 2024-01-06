//
//  ExecuteProgressDetails.swift
//  RsyncSwiftUI
//
//  Created by Thomas Evensen on 18/02/2021.
//

import Foundation

final class ExecuteProgressDetails: ObservableObject {
    // Value for storing progress for current task in work
    var currenttaskprogress: Double = 0
    var hiddenIDatwork: Int = -1
    var estimatedlist: [RemoteDataNumbers]?
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
        profile = nil
    }

    func setprofileandnumberofconfigurations(_ profilename: String, _ num: Int) {
        profile = profilename
        numberofconfigurations = num
    }

    deinit {
        // print("deinit ProgressDetails")
    }
}
