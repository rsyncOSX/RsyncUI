//
//  DecodeScheduleJSON.swift
//  RsyncOSX
//
//  Created by Thomas Evensen on 18/10/2020.
//  Copyright © 2020 Thomas Evensen. All rights reserved.
//
//	Model file generated using JSONExport: https://github.com/Ahmed-Ali/JSONExport

import Foundation

struct Logrecord: Codable, Hashable {
    let dateExecuted: String?
    let resultExecuted: String?

    enum CodingKeys: String, CodingKey {
        case dateExecuted
        case resultExecuted
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        dateExecuted = try values.decodeIfPresent(String.self, forKey: .dateExecuted)
        resultExecuted = try values.decodeIfPresent(String.self, forKey: .resultExecuted)
    }
}

struct CodableSchedule: Codable {
    let dateStart: String?
    let dateStop: String?
    let hiddenID: Int?
    let logrecords: [Logrecord]?
    let offsiteserver: String?
    let schedule: String?
    let profilename: String?

    enum CodingKeys: String, CodingKey {
        case dateStart
        case dateStop
        case hiddenID
        case logrecords
        case offsiteserver
        case schedule
        case profilename
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        dateStart = try values.decodeIfPresent(String.self, forKey: .dateStart)
        dateStop = try values.decodeIfPresent(String.self, forKey: .dateStop)
        hiddenID = try values.decodeIfPresent(Int.self, forKey: .hiddenID)
        logrecords = try values.decodeIfPresent([Logrecord].self, forKey: .logrecords)
        offsiteserver = try values.decodeIfPresent(String.self, forKey: .offsiteserver)
        schedule = try values.decodeIfPresent(String.self, forKey: .schedule)
        profilename = try values.decodeIfPresent(String.self, forKey: .profilename)
    }
}
