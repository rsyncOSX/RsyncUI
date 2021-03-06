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
        // print(" -> \(currenttaskprogress ?? 0)")
        return currenttaskprogress ?? 0
    }

    func getmaxcountbytask(_ hiddenID: Int) -> Double {
        let max = estimatedlist?.filter { $0.hiddenID == hiddenID }
        if (max?.count ?? 0) == 1 {
            let maxnum = Double(max?[0].transferredNumber ?? "0") ?? 0
            if maxnum < (currenttaskprogress ?? 0) {
                // print(" maxcount \(currenttaskprogress ?? 0)")
                return (currenttaskprogress ?? 0)
            } else {
                // print(" maxcount \(maxnum)")
                return maxnum
            }
        }
        return 0
    }

    func setestimatedlist(_ argestimatedlist: [RemoteinfonumbersOnetask]?) {
        estimatedlist = argestimatedlist
    }

    func resetcounter() {
        currenttaskprogress = 0
        estimatedlist = nil
    }
}
