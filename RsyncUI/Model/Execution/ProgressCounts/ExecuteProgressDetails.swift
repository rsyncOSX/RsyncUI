//
//  ExecuteProgressDetails.swift
//  RsyncSwiftUI
//
//  Created by Thomas Evensen on 18/02/2021.
//

import Foundation

final class ExecuteProgressDetails: ObservableObject {
    // Value for storing progress for current task in work
    @Published var currenttaskprogress: Double = 0

    var hiddenIDatwork: Int = -1
    var estimatedlist: [RemoteDataNumbers]?

    func taskisestimatedbyUUID(_ uuid: UUID) -> Bool {
        let answer = estimatedlist?.contains(where: { task in
            task.id == uuid
        }) ?? false ? true : false
        return answer
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
    }

    deinit {
        // print("deinit ProgressDetails")
    }
}
