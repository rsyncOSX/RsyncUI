//
//  InprogressCount.swift
//  RsyncSwiftUI
//
//  Created by Thomas Evensen on 18/01/2021.
//

import Foundation

protocol UpdateOutputprocessCountProtcol: AnyObject {
    func updateinprogresscount(num: Double)
    func getmaxcount() -> Int
    func setmaxcount(num: Int)
    func setoutput(data: [String]?)
    func getoutput() -> [Outputrecord]?
}

final class InprogressCountRsyncOutput: ObservableObject, UpdateOutputprocessCountProtcol {
    private var inprogresscount: Double = 0
    private var max: Int = 0
    private var output: [String]?

    func resetcounts() {
        max = 0
        inprogresscount = 0
        output = nil
    }

    func setmaxcount(num: Int) {
        max = num
    }

    func getmaxcount() -> Int {
        return max
    }

    func getinprogress() -> Double {
        return inprogresscount
    }

    func updateinprogresscount(num: Double) {
        inprogresscount = num
        objectWillChange.send()
    }

    func setoutput(data: [String]?) {
        output = data
    }

    func getoutput() -> [Outputrecord]? {
        guard output?.count ?? 0 > 0 else { return nil }
        var transformedoutput = [Outputrecord]()
        for i in 0 ..< (output?.count ?? 0) {
            transformedoutput.append(Outputrecord(line: output?[i] ?? ""))
        }
        return transformedoutput
    }

    deinit {
        // print("deinit InprogressCountRsyncOutput")
    }
}
