//
//  UserConfiguration.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 12/02/2022.
//

import Foundation

struct UserConfiguration: Codable {
    var version3rsync: Int?

    // Used when reading JSON data from store
    // see in ReadScheduleJSON
    init(_ data: DecodeUserConfiguration) {
        version3rsync = data.version3rsync ?? -1
    }

    // Create an empty record with no values
    init() {
        version3rsync = -1
    }
}
