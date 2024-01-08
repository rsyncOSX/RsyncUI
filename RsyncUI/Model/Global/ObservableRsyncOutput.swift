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
    private var output: [String]?

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
