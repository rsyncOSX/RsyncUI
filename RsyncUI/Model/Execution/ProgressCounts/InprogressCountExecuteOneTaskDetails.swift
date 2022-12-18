//
//  InprogressCountExecuteOneTaskDetails.swift
//  RsyncSwiftUI
//
//  Created by Thomas Evensen on 18/02/2021.
//

import Foundation

protocol ExecuteDetailsProtocol: AnyObject {
    // Update progress of count for current task in progress
    func setcurrentprogress(_ num: Double)
    func getcurrentprogress() -> Double
}

final class InprogressCountExecuteOneTaskDetails: ObservableObject, ExecuteDetailsProtocol {
    // Value for storing progress for current task in work
    private var currenttaskprogress: Double?
    private var estimatedlist: [RemoteinfonumbersOnetask]?

    func isestimating() -> Bool {
        if (estimatedlist?.count ?? 0) == 0 {
            return true
        } else {
            return false
        }
    }

    func setcurrentprogress(_ num: Double) {
        currenttaskprogress = num
        objectWillChange.send()
    }

    func getcurrentprogress() -> Double {
        print(" getcurrentprogress -> \(currenttaskprogress)")
        return currenttaskprogress ?? 0
    }

    func getmaxcountbytask(_ hiddenID: Int) -> Double {
        let max = estimatedlist?.filter { $0.hiddenID == hiddenID }
        if (max?.count ?? 0) == 1 {
            return Double(max?[0].outputfromrsync?.count ?? 0)
        } else {
            return 0
        }
    }

    func setestimatedlist(_ argestimatedlist: [RemoteinfonumbersOnetask]?) {
        estimatedlist = argestimatedlist
    }

    func resetcounter() {
        currenttaskprogress = 0
        estimatedlist = nil
    }
}
