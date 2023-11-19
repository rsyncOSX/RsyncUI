//
//  MultipleTaskState14.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 19/11/2023.
//

import Foundation
import Observation

@available(macOS 14.0, *)
@Observable
final class MultipleTaskState14 {
    var executionstate: ExecutetaskWork = .start

    func updatestate(state: ExecutetaskWork) {
        executionstate = state
    }

    deinit {
        // print("deinit MultipleTaskState")
    }
}
