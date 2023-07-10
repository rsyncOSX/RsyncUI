//
//  InprogressCount.swift
//  RsyncSwiftUI
//
//  Created by Thomas Evensen on 18/01/2021.
//

import Foundation
import Observation

protocol UpdateOutputprocessCountProtcol: AnyObject {
    func updateinprogresscount(num: Double)
    func getmaxcount() -> Int
    func setmaxcount(num: Int)
    func setoutput(data: [String]?)
    func getoutput() -> [String]?
}

@Observable
final class InprogressCountRsyncOutput: UpdateOutputprocessCountProtcol {
    private var inprogresscount: Double = 0
    private var max: Int = 0
    private var output: [String]?

    // For Quicktasks
    var myoutputprocess: OutputfromProcess?

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
    }

    func setoutput(data: [String]?) {
        output = data
    }

    func getoutput() -> [String]? {
        return output
    }

    func setoutput() {
        output = myoutputprocess?.getOutput()
    }

    init(outputprocess: OutputfromProcess?) {
        myoutputprocess = outputprocess
    }

    deinit {
        // print("deinit InprogressCountRsyncOutput")
    }
}
