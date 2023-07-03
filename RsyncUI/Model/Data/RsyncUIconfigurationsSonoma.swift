//
//  RsyncUIconfigurationsSonoma.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 03/07/2023.
//

import Observation
import SwiftUI

@available(macOS 14, *)
@Observable final class RsyncUIconfigurationsSonoma {
    var configurations: [Configuration]? = [Configuration]()
    var profile: String? = ""

    var configurationsfromstore: Readconfigurationsfromstore? = Readconfigurationsfromstore(profile: nil)
    var validhiddenIDs: Set<Int>? = Set<Int>()

    func filterconfigurations(_ filter: String) -> [Configuration]? {
        return configurations?.filter {
            filter.isEmpty ? true : $0.backupID.contains(filter)
        }
    }

    // Function for getting Configurations read into memory
    func getconfiguration(hiddenID: Int) -> Configuration? {
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

    init(profile: String?) {
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
