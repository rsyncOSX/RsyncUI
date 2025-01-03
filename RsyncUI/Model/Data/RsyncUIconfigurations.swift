//
//  RsyncUIconfigurations.swift
//  RsyncOSX
//
//  Created by Thomas Evensen on 28/12/2020.
//  Copyright © 2020 Thomas Evensen. All rights reserved.
//

import Observation
import SwiftUI

@Observable @MainActor
final class RsyncUIconfigurations {
    var configurations: [SynchronizeConfiguration]?
    var profile: String?
    @ObservationIgnored var readdatafromstorecompleted: Bool = false

    init() {}
}
