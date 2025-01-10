//
//  WidgetProfilenames.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 10/01/2025.
//

import Foundation
import Observation

struct WidgetProfilesnamesRecord: Hashable, Identifiable {
    var profile: String?
    let id = UUID()

    init(_ name: String) {
        profile = name
    }
}

final class WidgetProfilenames {
    var profiles: [WidgetProfilesnamesRecord]?

    var allprofiles: [String] {
        WidgetHomepath().getfullpathmacserialcatalogsasstringnames()
    }

    func update() {
        profiles = allprofiles.map { profile in
            WidgetProfilesnamesRecord(profile)
        }
    }

    init() {
        profiles = allprofiles.map { profile in
            WidgetProfilesnamesRecord(profile)
        }
    }
}
