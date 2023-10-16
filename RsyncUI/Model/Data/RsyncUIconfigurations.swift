//
//  RsyncUIconfigurations.swift
//  RsyncOSX
//
//  Created by Thomas Evensen on 28/12/2020.
//  Copyright © 2020 Thomas Evensen. All rights reserved.
//

import Observation
import SwiftUI

struct Readconfigurationsfromstore {
    var configurations: [Configuration]?
    var validhiddenIDs: Set<Int>

    init(profile: String?) {
        let configurationsfromstore = AllConfigurations(profile: profile)
        configurations = configurationsfromstore.configurations
        validhiddenIDs = configurationsfromstore.validhiddenIDs ?? Set()
    }
}

@Observable
final class RsyncUIconfigurations {
    var configurations: [Configuration]?
    var profile: String? = ""

    var configurationsfromstore: Readconfigurationsfromstore?
    var validhiddenIDs: Set<Int>? = Set<Int>()

    func filterconfigurations(_ filter: String) -> [Configuration]? {
        return configurations?.filter {
            filter.isEmpty ? true : $0.backupID.contains(filter)
        }
    }

    // Function for getting Configurations read into memory
    func getconfig(hiddenID: Int) -> Configuration? {
        let configuration = configurations?.filter { $0.hiddenID == hiddenID }
        guard configuration?.count == 1 else { return nil }
        return configuration?[0]
    }

    // Function for getting Configurations read into memory, sorted by runddate
    func getallconfigurations() -> [Configuration]? {
        if let configurations = configurations {
            let sorted = configurations.sorted { conf1, conf2 in
                if let days1 = conf1.dateRun?.en_us_date_from_string(),
                   let days2 = conf2.dateRun?.en_us_date_from_string()
                {
                    return days1 > days2
                }
                return false
            }
            return sorted
        }
        return nil
    }

    init(profile: String?, _ reload: Bool) {
        if reload == false {
            self.profile = profile
            if profile == SharedReference.shared.defaultprofile || profile == nil {
                configurationsfromstore = Readconfigurationsfromstore(profile: nil)
            } else {
                configurationsfromstore = Readconfigurationsfromstore(profile: profile)
            }
            configurations = configurationsfromstore?.configurations
            validhiddenIDs = configurationsfromstore?.validhiddenIDs
            // Release struct
            configurationsfromstore = nil
        }
    }
}
