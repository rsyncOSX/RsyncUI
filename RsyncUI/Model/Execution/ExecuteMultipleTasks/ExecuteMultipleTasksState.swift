//
//  ExecuteMultipleTasksState.swift
//  RsyncSwiftUI
//
//  Created by Thomas Evensen on 22/01/2021.
//

import Foundation
import Observation

import Foundation
import Observation

enum ExecuteWorkState: String, CaseIterable, Identifiable, CustomStringConvertible {
    case start
    case execute
    case completed

    var id: String { rawValue }
    var description: String { rawValue.localizedCapitalized }
}

@Observable
final class ExecuteMultipleTasksState {
    var executestate: ExecuteWorkState = .start

    func updateexecutestate(state: ExecuteWorkState) {
        executestate = state
    }
}
