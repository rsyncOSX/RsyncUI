//
//  RsyncUIconfigurations.swift
//  RsyncOSX
//
//  Created by Thomas Evensen on 28/12/2020.
//  Copyright © 2020 Thomas Evensen. All rights reserved.
//

import Observation
import SwiftUI

@Observable
final class RsyncUIconfigurations {
    var configurations: [SynchronizeConfiguration]?
    var profile: String?
    @ObservationIgnored var validhiddenIDs: Set<Int>?

    func resetandupdatevalidhiddenIDS() {
        if validhiddenIDs == nil {
            validhiddenIDs = Set<Int>()
        } else {
            validhiddenIDs?.removeAll()
        }
        for i in 0 ..< (configurations?.count ?? 0) {
            validhiddenIDs?.insert(configurations?[i].hiddenID ?? -1)
        }
    }

    init(_ profile: String?,
         _ configurationsfromstore: [SynchronizeConfiguration]?,
         _ validehiddenIDsfromstore: Set<Int>?)
    {
        self.profile = profile
        configurations = configurationsfromstore
        validhiddenIDs = validehiddenIDsfromstore
    }
}
