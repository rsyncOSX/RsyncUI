//
//  Profilenames.swift
//  RsyncSwiftUI
//
//  Created by Thomas Evensen on 01/03/2021.
//

import Foundation
import Observation

struct ProfilesnamesRecord: Identifiable, Equatable, Hashable {
    var profilename: String
    let id = UUID()

    init(_ name: String) {
        profilename = name
    }
}

@Observable @MainActor
final class Profilenames {
    var profiles: [ProfilesnamesRecord]?

    /*
     func update(_ allprofiles: [String]) {
         profiles = allprofiles.map { profile in
             ProfilesnamesRecord(profile)
         }
     }
     */
    init(_ allprofiles: [String]?) {
        if let allprofiles {
            profiles = allprofiles.map { profile in
                ProfilesnamesRecord(profile)
            }
        } else {
            profiles = nil
        }
    }
}
