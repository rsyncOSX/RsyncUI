//
//  RsyncUIconfigurations.swift
//  RsyncOSX
//
//  Created by Thomas Evensen on 28/12/2020.
//  Copyright © 2020 Thomas Evensen. All rights reserved.
//

import Observation
import SwiftUI

struct ProfilesnamesRecord: Identifiable, Equatable, Hashable {
    var profilename: String
    let id = UUID()

    init(_ name: String) {
        profilename = name
    }
}

@Observable @MainActor
final class RsyncUIconfigurations {
    var configurations: [SynchronizeConfiguration]?
    var profile: String?
    // This is observed when URL actions are initiated.
    // Befor commence the real action must be sure that selected profile data is loaded from store
    var readdatafromstorecompleted: Bool = true
    var validprofiles: [ProfilesnamesRecord] = []
    // Toggle sidebar
    var columnVisibility = NavigationSplitViewVisibility.doubleColumn
    // .doubleColumn or .detailOnly
    var oneormoretasksissnapshot: Bool = false
    var oneormoretasksisremote: Bool = false

    init() {}
}
