//
//  DecodeUserConfiguration.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 12/02/2022.
//

import Foundation

struct DecodeUserConfiguration: Codable {
    let rsyncversion3: Int?

    enum CodingKeys: String, CodingKey {
        case rsyncversion3
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        rsyncversion3 = try values.decodeIfPresent(Int.self, forKey: .rsyncversion3)
    }

    // This init is used in WriteScheduleJSON
    init(_ data: UserConfiguration) {
        rsyncversion3 = data.rsyncversion3
    }
}
