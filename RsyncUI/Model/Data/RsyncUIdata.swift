//
//  rsyncUIdata.swift
//  RsyncOSX
//
//  Created by Thomas Evensen on 28/12/2020.
//  Copyright © 2020 Thomas Evensen. All rights reserved.
//

import SwiftUI

struct Readconfigurationsfromstore {
    var profile: String?
    var configurationData: ConfigurationsSwiftUI
    var validhiddenIDs: Set<Int>

    init(profile: String?) {
        self.profile = profile
        configurationData = ConfigurationsSwiftUI(profile: self.profile)
        validhiddenIDs = configurationData.getvalidhiddenIDs() ?? Set()
    }
}

final class RsyncUIdata: ObservableObject {
    @Published var rsyncdata: Readconfigurationsfromstore?
    var configurations: [Configuration]?
    var profile: String?
    var validhiddenIDs: Set<Int>?

    func filterconfigurations(_ filter: String) -> [Configuration]? {
        return configurations?.filter {
            filter.isEmpty ? true : $0.backupID.contains(filter)
        }
    }

    init(profile: String?) {
        guard SharedReference.shared.reload == true else {
            SharedReference.shared.reload = true
            return
        }
        self.profile = profile
        if profile == SharedReference.shared.defaultprofile || profile == nil {
            rsyncdata = Readconfigurationsfromstore(profile: nil)
        } else {
            rsyncdata = Readconfigurationsfromstore(profile: profile)
        }
        configurations = rsyncdata?.configurationData.getallconfigurations()
        validhiddenIDs = rsyncdata?.validhiddenIDs
    }
}
