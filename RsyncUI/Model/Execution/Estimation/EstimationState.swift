//
//  EstimationState.swift
//  RsyncSwiftUI
//
//  Created by Thomas Evensen on 19/01/2021.
//

import Foundation

final class EstimationState: ObservableObject {
    @Published var estimationstate: EstimatetaskWork = .start

    func updatestate(state: EstimatetaskWork) {
        estimationstate = state
    }

    deinit {
        // print("deinit EstimationState")
    }
}
