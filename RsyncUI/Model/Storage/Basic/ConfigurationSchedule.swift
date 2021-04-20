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
    var delete: Bool?
    var date: Date {
        return dateExecuted?.en_us_date_from_string() ?? Date()
    }
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

    init(dictionary: NSDictionary, log: NSArray?) {
        hiddenID = dictionary.object(forKey: DictionaryStrings.hiddenID.rawValue) as? Int ?? -1
        dateStart = dictionary.object(forKey: DictionaryStrings.dateStart.rawValue) as? String ?? ""
        schedule = dictionary.object(forKey: DictionaryStrings.schedule.rawValue) as? String ?? ""
        offsiteserver = dictionary.object(forKey: DictionaryStrings.offsiteserver.rawValue) as? String ?? ""
        if let date = dictionary.object(forKey: DictionaryStrings.dateStop.rawValue) as? String { dateStop = date }
        if log != nil {
            for i in 0 ..< (log?.count ?? 0) {
                if i == 0 { logrecords = [Log]() }
                var logrecord = Log()
                if let dict = log?[i] as? NSDictionary {
                    logrecord.dateExecuted = dict.object(forKey: DictionaryStrings.dateExecuted.rawValue) as? String
                    logrecord.resultExecuted = dict.object(forKey: DictionaryStrings.resultExecuted.rawValue) as? String
                }
                logrecords?.append(logrecord)
            }
        }
        if logrecords == nil { logrecords = [] }
    }

    // Codable init
    init(schedule: Self) {
        hiddenID = schedule.hiddenID
        offsiteserver = schedule.offsiteserver
        dateStart = schedule.dateStart
        dateStop = schedule.dateStop
        self.schedule = schedule.schedule
        if (schedule.logrecords?.count ?? 0) > 0 { logrecords = [Log]() }
        for i in 0 ..< (schedule.logrecords?.count ?? 0) {
            var onelogrecord = Log()
            onelogrecord.dateExecuted = schedule.logrecords?[i].dateExecuted
            onelogrecord.resultExecuted = schedule.logrecords?[i].resultExecuted
            logrecords?.append(onelogrecord)
        }
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
