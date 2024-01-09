//
//  DecodeConfigurationSchedule.swift
//  RsyncOSX
//
//  Created by Thomas Evensen on 18/10/2020.
//  Copyright © 2020 Thomas Evensen. All rights reserved.
//
//	Model file generated using JSONExport: https://github.com/Ahmed-Ali/JSONExport

import Foundation

struct Logrecord: Codable, Hashable {
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

struct DecodeConfigurationSchedule: Codable {
    let dateStart: String?
    let hiddenID: Int?
    var logrecords: [Logrecord]?
    let offsiteserver: String?
    // let schedule: String?
    let profilename: String?

    enum CodingKeys: String, CodingKey {
        case dateStart
        case hiddenID
        case logrecords
        case offsiteserver
        // case schedule
        case profilename
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        dateStart = try values.decodeIfPresent(String.self, forKey: .dateStart)
        hiddenID = try values.decodeIfPresent(Int.self, forKey: .hiddenID)
        logrecords = try values.decodeIfPresent([Logrecord].self, forKey: .logrecords)
        offsiteserver = try values.decodeIfPresent(String.self, forKey: .offsiteserver)
        // schedule = try values.decodeIfPresent(String.self, forKey: .schedule)
        profilename = try values.decodeIfPresent(String.self, forKey: .profilename)
    }

    // This init is used in WriteScheduleJSON
    init(_ data: LogRecords) {
        dateStart = data.dateStart
        hiddenID = data.hiddenID
        offsiteserver = data.offsiteserver
        // schedule = data.schedule
        profilename = data.profilename
        for i in 0 ..< (data.logrecords?.count ?? 0) {
            if i == 0 { logrecords = [Logrecord]() }
            var log = Logrecord()
            log.dateExecuted = data.logrecords?[i].dateExecuted
            log.resultExecuted = data.logrecords?[i].resultExecuted
            logrecords?.append(log)
        }
    }
}
