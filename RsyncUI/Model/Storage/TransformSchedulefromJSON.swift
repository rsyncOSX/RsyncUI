//
//  TransformSchedulefromJSON.swift
//  RsyncOSX
//
//  Created by Thomas Evensen on 31/10/2020.
//  Copyright © 2020 Thomas Evensen. All rights reserved.
//
// swiftlint:disable trailing_comma

import Foundation

struct TransformSchedulefromJSON {
    func transform(_ object: DecodeSchedule) -> ConfigurationSchedule {
        var log: [Any]?
        let dict: NSMutableDictionary = [
            DictionaryStrings.hiddenID.rawValue: object.hiddenID ?? -1,
            DictionaryStrings.offsiteserver.rawValue: object.offsiteserver ?? "",
            DictionaryStrings.dateStart.rawValue: object.dateStart ?? "",
            DictionaryStrings.schedule.rawValue: object.schedule ?? "",
            DictionaryStrings.profilename.rawValue: object.profilename ?? "",
        ]
        if object.dateStop?.isEmpty == false {
            dict.setObject(object.dateStop ?? "", forKey: DictionaryStrings.dateStop.rawValue as NSCopying)
        }
        for i in 0 ..< (object.logrecords?.count ?? 0) {
            if i == 0 { log = Array() }
            let logdict: NSMutableDictionary = [
                DictionaryStrings.dateExecuted.rawValue: object.logrecords![i].dateExecuted ?? "",
                DictionaryStrings.resultExecuted.rawValue: object.logrecords![i].resultExecuted ?? "",
            ]
            log?.append(logdict)
        }
        return ConfigurationSchedule(dictionary: dict as NSDictionary, log: log as NSArray?)
    }
}
