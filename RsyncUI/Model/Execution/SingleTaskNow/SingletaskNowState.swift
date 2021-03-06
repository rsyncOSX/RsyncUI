//
//  SingletaskNowState.swift
//  RsyncSwiftUI
//
//  Created by Thomas Evensen on 18/01/2021.
//

import Foundation

final class SingletaskNowState: ObservableObject {
    var executetasknowstate: ExecutetasknowWork = .start

    func updatestate(state: ExecutetasknowWork) {
        executetasknowstate = state
        objectWillChange.send()
    }

    deinit {
        // print("deinit SingletaskNowState")
    }
}
