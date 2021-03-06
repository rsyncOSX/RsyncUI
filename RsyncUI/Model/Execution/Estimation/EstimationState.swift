//
//  EstimationState.swift
//  RsyncSwiftUI
//
//  Created by Thomas Evensen on 19/01/2021.
//

import Foundation

final class EstimationState: ObservableObject {
    var estimationstate: EstimatetaskWork = .start

    func updatestate(state: EstimatetaskWork) {
        estimationstate = state
        objectWillChange.send()
    }

    deinit {
        // print("deinit EstimationState")
    }
}
