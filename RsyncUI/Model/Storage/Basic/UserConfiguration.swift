//
//  UserConfiguration.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 12/02/2022.
//

import Foundation

struct UserConfiguration: Codable {
    var rsyncversion3: Int = -1
    // Detailed logging
    var detailedlogging: Int = 1
    // Logging to logfile
    var minimumlogging: Int = -1
    var fulllogging: Int = -1
    var nologging: Int = 1

    // Used when reading JSON data from store
    // see in ReadScheduleJSON
    init(_ data: DecodeUserConfiguration) {
        rsyncversion3 = data.rsyncversion3 ?? -1
        detailedlogging = data.detailedlogging ?? 1
        minimumlogging = data.minimumlogging ?? -1
        fulllogging = data.fulllogging ?? -1
        nologging = data.nologging ?? 1
    }

    // Default values user configuration
    init() {}
}
