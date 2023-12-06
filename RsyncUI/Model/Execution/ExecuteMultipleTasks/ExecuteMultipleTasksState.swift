//
//  ExecuteMultipleTasksState.swift
//  RsyncSwiftUI
//
//  Created by Thomas Evensen on 22/01/2021.
//

import Foundation
import Observation

enum ExecutetaskWork: String, CaseIterable, Identifiable, CustomStringConvertible {
    case start
    case execute
    case completed

    var id: String { rawValue }
    var description: String { rawValue.localizedCapitalized }
}

@Observable
final class ExecuteMultipleTasksState {
    var executionstate: ExecutetaskWork = .start

    func updatestate(state: ExecutetaskWork) {
        executionstate = state
    }

    deinit {
        // print("deinit MultipleTaskState")
    }
}
