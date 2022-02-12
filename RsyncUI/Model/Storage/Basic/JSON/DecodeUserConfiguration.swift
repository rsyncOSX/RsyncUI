//
//  DecodeUserConfiguration.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 12/02/2022.
//

import Foundation

struct DecodeUserConfiguration: Codable {
    let version3rsync: Int?

    enum CodingKeys: String, CodingKey {
        case version3rsync
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        version3rsync = try values.decodeIfPresent(Int.self, forKey: .version3rsync)
    }

    // This init is used in WriteScheduleJSON
    init(_ data: UserConfiguration) {
        version3rsync = data.version3rsync
    }
}
