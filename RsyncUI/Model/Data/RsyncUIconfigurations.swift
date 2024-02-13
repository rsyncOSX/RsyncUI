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

    init(_ profile: String?) {
        self.profile = profile
        if profile == SharedReference.shared.defaultprofile || profile == nil {
            configurations = ReadConfigurationJSON(nil).configurations
        } else {
            configurations = ReadConfigurationJSON(profile).configurations
        }
    }
}
