//
//  ConfigurationSchedulePLIST.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 23/05/2021.
//

import Foundation

struct ConfigurationSchedulePLIST {
    var hiddenID: Int
    var offsiteserver: String?
    var dateStart: String
    var dateStop: String?
    var schedule: String
    var logrecords: [Log]?
    var profilename: String?

    // Used when reading PLIST data from store (as part of converting to JSON)
    // And also when creating new records.
    init(dictionary: NSDictionary, log: NSArray?) {
        hiddenID = dictionary.object(forKey: DictionaryStrings.hiddenID.rawValue) as? Int ?? -1
        dateStart = dictionary.object(forKey: DictionaryStrings.dateStart.rawValue) as? String ?? ""
        schedule = dictionary.object(forKey: DictionaryStrings.schedule.rawValue) as? String ?? ""
        offsiteserver = dictionary.object(forKey: DictionaryStrings.offsiteserver.rawValue) as? String ?? ""
        if let date = dictionary.object(forKey: DictionaryStrings.dateStop.rawValue) as? String { dateStop = date }
        if let log = log {
            for i in 0 ..< log.count {
                if i == 0 { logrecords = [Log]() }
                var logrecord = Log()
                if let dict = log[i] as? NSDictionary {
                    logrecord.dateExecuted = dict.object(forKey: DictionaryStrings.dateExecuted.rawValue) as? String
                    logrecord.resultExecuted = dict.object(forKey: DictionaryStrings.resultExecuted.rawValue) as? String
                }
                logrecords?.append(logrecord)
            }
        }
    }
}
