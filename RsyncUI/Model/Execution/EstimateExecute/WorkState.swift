//
//  ExecuteState.swift
//  RsyncSwiftUI
//
//  Created by Thomas Evensen on 22/01/2021.
//

import Foundation
import Observation

enum EnumWorkState: String, CaseIterable, Identifiable, CustomStringConvertible {
    case start
    case execute
    case completed

    var id: String { rawValue }
    var description: String { rawValue.localizedCapitalized }
}

@Observable
final class WorkState {
    var executestate: EnumWorkState = .start

    func updatestate(_ state: EnumWorkState) {
        executestate = state
    }
}
