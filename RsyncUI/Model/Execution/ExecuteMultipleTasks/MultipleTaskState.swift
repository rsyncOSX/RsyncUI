//
//  MultipleTaskState.swift
//  RsyncSwiftUI
//
//  Created by Thomas Evensen on 22/01/2021.
//

import Foundation
import Observation

@Observable
final class MultipleTaskState {
    var executionstate: ExecutetaskWork = .start

    func updatestate(state: ExecutetaskWork) {
        executionstate = state
    }

    deinit {
        // print("deinit MultipleTaskState")
    }
}
