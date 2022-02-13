//
//  DecodeUserConfiguration.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 12/02/2022.
//

import Foundation

struct DecodeUserConfiguration: Codable {
    let rsyncversion3: Int?
    // Detailed logging
    let detailedlogging: Int?
    // Logging to logfile
    let minimumlogging: Int?
    let fulllogging: Int?
    let nologging: Int?

    enum CodingKeys: String, CodingKey {
        case rsyncversion3
        case detailedlogging
        case minimumlogging
        case fulllogging
        case nologging
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        rsyncversion3 = try values.decodeIfPresent(Int.self, forKey: .rsyncversion3)
        detailedlogging = try values.decodeIfPresent(Int.self, forKey: .detailedlogging)
        minimumlogging = try values.decodeIfPresent(Int.self, forKey: .minimumlogging)
        fulllogging = try values.decodeIfPresent(Int.self, forKey: .fulllogging)
        nologging = try values.decodeIfPresent(Int.self, forKey: .nologging)
    }

    init(_ userconfiguration: UserConfiguration) {
        rsyncversion3 = userconfiguration.rsyncversion3
        detailedlogging = userconfiguration.detailedlogging
        minimumlogging = userconfiguration.minimumlogging
        fulllogging = userconfiguration.fulllogging
        nologging = userconfiguration.nologging
    }
}
