//
//  DecodeLogRecords.swift
//  RsyncOSX
//
//  Created by Thomas Evensen on 18/10/2020.
//  Copyright © 2020 Thomas Evensen. All rights reserved.
//

import Foundation

struct DecodeLogRecords: Codable {
    let dateStart: String?
    let hiddenID: Int?
    var logrecords: [DecodeLog]?
    let offsiteserver: String?
    let profilename: String?

    enum CodingKeys: String, CodingKey {
        case dateStart
        case hiddenID
        case logrecords
        case offsiteserver
        case profilename
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        dateStart = try values.decodeIfPresent(String.self, forKey: .dateStart)
        hiddenID = try values.decodeIfPresent(Int.self, forKey: .hiddenID)
        logrecords = try values.decodeIfPresent([DecodeLog].self, forKey: .logrecords)
        offsiteserver = try values.decodeIfPresent(String.self, forKey: .offsiteserver)
        profilename = try values.decodeIfPresent(String.self, forKey: .profilename)
    }

    init(_ data: LogRecords) {
        dateStart = data.dateStart
        hiddenID = data.hiddenID
        offsiteserver = data.offsiteserver
        profilename = data.profilename
        for i in 0 ..< (data.logrecords?.count ?? 0) {
            if i == 0 { logrecords = [DecodeLog]() }
            var log = DecodeLog()
            log.dateExecuted = data.logrecords?[i].dateExecuted
            log.resultExecuted = data.logrecords?[i].resultExecuted
            logrecords?.append(log)
        }
    }
}

struct DecodeLog: Codable, Hashable {
    var dateExecuted: String?
    var resultExecuted: String?

    enum CodingKeys: String, CodingKey {
        case dateExecuted
        case resultExecuted
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        dateExecuted = try values.decodeIfPresent(String.self, forKey: .dateExecuted)
        resultExecuted = try values.decodeIfPresent(String.self, forKey: .resultExecuted)
    }

    // This init is used in WriteConfigurationJSON
    init() {
        dateExecuted = nil
        resultExecuted = nil
    }
}
