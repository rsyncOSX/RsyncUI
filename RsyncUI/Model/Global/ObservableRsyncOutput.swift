//
//  ObservableRsyncOutput.swift
//  RsyncSwiftUI
//
//  Created by Thomas Evensen on 18/01/2021.
//

import Foundation
import Observation

@Observable
final class ObservableRsyncOutput {
    private var max: Int = 0
    private var output: [String]?

    func resetcounts() {
        max = 0
        output = nil
    }

    func setmaxcount(_ num: Int) {
        max = num
    }

    func getmaxcount() -> Int {
        return max
    }

    func setoutput(_ data: [String]?) {
        output = data
    }

    func getoutput() -> [String]? {
        return output
    }

    deinit {
        // print("deinit InprogressCountRsyncOutput")
    }
}
