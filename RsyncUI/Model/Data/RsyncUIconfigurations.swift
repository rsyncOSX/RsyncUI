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
    // This is observed when URL actions are initiated.
    // Befor commence the real action must be sure that selected profile data is loaded from store
    @ObservationIgnored var readdatafromstorecompleted: Bool = false

    init() {}
}
