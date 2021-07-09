//
//  SingleTaskState.swift
//  RsyncSwiftUI
//
//  Created by Thomas Evensen on 18/01/2021.
//

import Foundation

final class SingleTaskState: ObservableObject {
    var singletaskstate: SingleTaskWork = .start

    var estimateonly: Bool = false

    func updatestate(state: SingleTaskWork) {
        singletaskstate = state
        objectWillChange.send()
    }

    deinit {
        // print("deinit SingleTaskState")
    }
}
