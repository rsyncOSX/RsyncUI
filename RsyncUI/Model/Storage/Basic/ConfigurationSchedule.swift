//
//  ConfigurationSchedule.swift
//  RsyncOSX
//
//  Created by Thomas Evensen on 02/05/16.
//  Copyright © 2016 Thomas Evensen. All rights reserved.
//

import Foundation

struct Log: Identifiable, Codable {
    var id = UUID()
    var dateExecuted: String?
    var resultExecuted: String?
    var date: Date {
        return dateExecuted?.en_us_date_from_string() ?? Date()
    }

    // Used only in view logs
    var hiddenID: Int?
}

struct ConfigurationSchedule: Identifiable, Codable {
    var id = UUID()
    var hiddenID: Int
    var offsiteserver: String?
    var dateStart: String
    var dateStop: String?
    var schedule: String
    var logrecords: [Log]?
    var profilename: String?

    // Used when reading JSON data from store
    // see in ReadScheduleJSON
    init(_ data: DecodeConfigurationSchedule) {
        dateStart = data.dateStart ?? ""
        dateStop = data.dateStop
        hiddenID = data.hiddenID ?? -1
        offsiteserver = data.offsiteserver
        schedule = data.schedule ?? ""
        for i in 0 ..< (data.logrecords?.count ?? 0) {
            if i == 0 { logrecords = [Log]() }
            var log = Log()
            log.dateExecuted = data.logrecords?[i].dateExecuted
            log.resultExecuted = data.logrecords?[i].resultExecuted
            log.hiddenID = hiddenID
            logrecords?.append(log)
        }
    }

    // Create an empty record with no values
    init() {
        hiddenID = -1
        dateStart = ""
        schedule = ""
    }
}

extension ConfigurationSchedule: Hashable, Equatable {
    static func == (lhs: ConfigurationSchedule, rhs: ConfigurationSchedule) -> Bool {
        return lhs.hiddenID == rhs.hiddenID &&
            lhs.dateStart == rhs.dateStart &&
            lhs.schedule == rhs.schedule &&
            lhs.dateStop == rhs.dateStop &&
            lhs.offsiteserver == rhs.offsiteserver
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(String(hiddenID))
        hasher.combine(dateStart)
        hasher.combine(schedule)
        hasher.combine(dateStop)
        hasher.combine(offsiteserver)
    }
}

extension Log: Hashable, Equatable {
    static func == (lhs: Log, rhs: Log) -> Bool {
        return lhs.dateExecuted == rhs.dateExecuted &&
            lhs.resultExecuted == rhs.resultExecuted &&
            lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(dateExecuted)
        hasher.combine(resultExecuted)
        hasher.combine(id)
    }
}
