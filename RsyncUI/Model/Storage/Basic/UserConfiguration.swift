//
//  UserConfiguration.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 12/02/2022.
//

import Foundation

struct UserConfiguration: Codable {
    var rsyncversion3: Int?

    // Used when reading JSON data from store
    // see in ReadScheduleJSON
    init(_ data: DecodeUserConfiguration) {
        rsyncversion3 = data.rsyncversion3 ?? -1
    }

    // Create an empty record with no values
    init() {
        rsyncversion3 = -1
    }
}
