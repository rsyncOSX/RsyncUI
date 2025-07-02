//
//  CheckfornewversionofRsyncUI.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 07/12/2022.
//

import Foundation
import Observation

struct VersionsofRsyncUI: Codable {
    let url: String?
    let version: String?

    enum CodingKeys: String, CodingKey {
        case url
        case version
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        url = try values.decodeIfPresent(String.self, forKey: .url)
        version = try values.decodeIfPresent(String.self, forKey: .version)
    }
}

@Observable @MainActor
final class CheckfornewversionofRsyncUI {
    var notifynewversion: Bool = false
    var downloadavaliable: Bool = false
}
