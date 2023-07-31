//
//  MultipleTaskState.swift
//  RsyncSwiftUI
//
//  Created by Thomas Evensen on 22/01/2021.
//

import Foundation

final class MultipleTaskState: ObservableObject {
    var executionstate: ExecutetaskWork = .start

    func updatestate(state: ExecutetaskWork) {
        executionstate = state
        objectWillChange.send()
    }

    deinit {
        // print("deinit MultipleTaskState")
    }
}
