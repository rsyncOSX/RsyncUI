//
//  Profilenames.swift
//  RsyncSwiftUI
//
//  Created by Thomas Evensen on 01/03/2021.
//

import Foundation
import Observation

struct ProfilesnamesRecord: Hashable, Identifiable {
    var profile: String?
    let id = UUID()

    init(_ name: String) {
        profile = name
    }
}

@Observable @MainActor
final class Profilenames {
    var profiles: [ProfilesnamesRecord]?

    var allprofiles: [String] {
        Homepath().getfullpathmacserialcatalogsasstringnames()
    }

    func update() {
        profiles = allprofiles.map { profile in
            ProfilesnamesRecord(profile)
        }
    }

    init() {
        profiles = allprofiles.map { profile in
            ProfilesnamesRecord(profile)
        }
    }
}
