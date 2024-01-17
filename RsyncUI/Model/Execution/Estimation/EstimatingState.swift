//
//  EstimatingState.swift
//  RsyncSwiftUI
//
//  Created by Thomas Evensen on 19/01/2021.
//

import Foundation
import Observation

enum EstimatetaskWork: String, CaseIterable, Identifiable, CustomStringConvertible {
    case start
    case estimate
    case completed

    var id: String { rawValue }
    var description: String { rawValue.localizedCapitalized }
}

@Observable
final class EstimatingState {
    var estimationstate: EstimatetaskWork = .start

    func updatestate(state: EstimatetaskWork) {
        estimationstate = state
    }
}
