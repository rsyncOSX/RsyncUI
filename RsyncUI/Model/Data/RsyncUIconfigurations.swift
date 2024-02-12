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

    init(_ profile: String?,
         _ configurationsfromstore: [SynchronizeConfiguration]?)
    {
        self.profile = profile
        configurations = configurationsfromstore
    }
}
