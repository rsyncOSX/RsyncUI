//
//  InprogressCount.swift
//  RsyncSwiftUI
//
//  Created by Thomas Evensen on 18/01/2021.
//

import Foundation

final class ObservableRsyncOutput: ObservableObject {
    private var max: Int = 0
    private var output: [String]?

    // For Quicktasks
    // var myoutputprocess: OutputfromProcess?

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

    /*
     func setoutput() {
         output = myoutputprocess?.getOutput()
     }

     init(_ outputprocess: OutputfromProcess?) {
         myoutputprocess = outputprocess
     }
     */
    deinit {
        print("deinit InprogressCountRsyncOutput")
    }
}
