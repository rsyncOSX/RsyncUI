//
//  EstimateState.swift
//  RsyncSwiftUI
//
//  Created by Thomas Evensen on 19/01/2021.
//

import Foundation
import Observation

enum EstimateWorkState: String, CaseIterable, Identifiable, CustomStringConvertible {
    case start
    case estimate
    case completed

    var id: String { rawValue }
    var description: String { rawValue.localizedCapitalized }
}

@Observable
final class EstimateState {
    var estimatestate: EstimateWorkState = .start

    func updateestimatestate(state: EstimateWorkState) {
        estimatestate = state
    }
}
