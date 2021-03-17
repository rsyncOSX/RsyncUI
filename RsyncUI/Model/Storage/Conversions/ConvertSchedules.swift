//
//  ConvertSchedules.swift
//  RsyncOSX
//
//  Created by Thomas Evensen on 26/04/2019.
//  Copyright © 2019 Thomas Evensen. All rights reserved.
//
// swiftlint:disable trailing_comma line_length

import Foundation

struct ConvertSchedules {
    var schedulesNSDictionary: [NSDictionary]?
    var cleanedschedules: [ConfigurationSchedule]?
    var schedules: [ConfigurationSchedule]?

    private mutating func convertNSDictionary() {
        var array = [NSDictionary]()
        if let schedules = self.schedules {
            for i in 0 ..< schedules.count {
                let dict: NSMutableDictionary = [
                    DictionaryStrings.hiddenID.rawValue: schedules[i].hiddenID,
                    DictionaryStrings.dateStart.rawValue: schedules[i].dateStart,
                    DictionaryStrings.schedule.rawValue: schedules[i].schedule,
                    DictionaryStrings.offsiteserver.rawValue: schedules[i].offsiteserver ?? DictionaryStrings.localhost.rawValue,
                ]
                if let log = schedules[i].logrecords {
                    var logrecords = [NSDictionary]()
                    for i in 0 ..< log.count {
                        let dict: NSDictionary = [
                            DictionaryStrings.dateExecuted.rawValue: log[i].dateExecuted ?? "",
                            DictionaryStrings.resultExecuted.rawValue: log[i].resultExecuted ?? "",
                        ]
                        logrecords.append(dict)
                    }
                    dict.setObject(logrecords, forKey: DictionaryStrings.executed.rawValue as NSCopying)
                }
                if schedules[i].dateStop != nil {
                    dict.setValue(schedules[i].dateStop, forKey: DictionaryStrings.dateStop.rawValue)
                }
                if schedules[i].delete ?? false == false {
                    array.append(dict)
                } else {
                    if schedules[i].logrecords?.isEmpty == false {
                        if schedules[i].delete ?? false == false {
                            array.append(dict)
                        }
                    }
                }
            }
        }
        schedulesNSDictionary = array
    }

    private mutating func convertJSON() {
        if let schedules = self.schedules {
            var cleaned = [ConfigurationSchedule]()
            for i in 0 ..< schedules.count {
                if schedules[i].delete ?? false == false {
                    cleaned.append(schedules[i])
                } else {
                    if schedules[i].logrecords?.isEmpty == false {
                        if schedules[i].delete ?? false == false {
                            cleaned.append(schedules[i])
                        }
                    }
                }
            }
            cleanedschedules = cleaned
        }
    }

    init(JSON: Bool, schedules: [ConfigurationSchedule]?) {
        self.schedules = schedules
        if JSON == false {
            convertNSDictionary()
        } else {
            convertJSON()
        }
    }
}
