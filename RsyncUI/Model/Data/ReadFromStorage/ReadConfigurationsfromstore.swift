//
//  ReadConfigurationsfromstore.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 18/01/2024.
//

import Foundation

struct ReadConfigurationsfromstore {
    var configurations: [SynchronizeConfiguration]?

    init(_ profile: String?) {
        var configurationsfromstore: ReadConfigurationJSON?
        if profile == SharedReference.shared.defaultprofile {
            configurationsfromstore = ReadConfigurationJSON(nil)
        } else {
            configurationsfromstore = ReadConfigurationJSON(profile)
        }
        configurations = configurationsfromstore?.configurations
    }
}
