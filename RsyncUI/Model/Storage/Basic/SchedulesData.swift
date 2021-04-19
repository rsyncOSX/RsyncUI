//
//  SchedulesData.swift
//  RsyncOSX
//
//  Created by Thomas Evensen on 15/11/2020.
//  Copyright © 2020 Thomas Evensen. All rights reserved.
//
// swiftlint:disable line_length

import Foundation

final class SchedulesData {
    var schedules: [ConfigurationSchedule]?
    var localprofile: String?
    var validhiddenID: Set<Int>?
    var persistentstorage: PersistentStorage?

    func readschedulesplist() {
        if let schedulesfromstore = persistentstorage?.schedulePLIST?.schedulesasdictionary {
            var schedule: ConfigurationSchedule?
            for i in 0 ..< schedulesfromstore.count {
                if let validhiddenID = self.validhiddenID {
                    let dict = schedulesfromstore[i]
                    if let hiddenID = dict.value(forKey: DictionaryStrings.hiddenID.rawValue) as? Int {
                        if validhiddenID.contains(hiddenID) {
                            if let log = dict.value(forKey: DictionaryStrings.executed.rawValue) {
                                schedule = ConfigurationSchedule(dictionary: dict, log: log as? NSArray)
                            } else {
                                schedule = ConfigurationSchedule(dictionary: dict, log: nil)
                            }
                            if let schedule = schedule {
                                schedules?.append(schedule)
                            }
                        }
                    }
                }
            }
            // Sorting schedule after hiddenID
            schedules?.sort { (schedule1, schedule2) -> Bool in
                if schedule1.hiddenID > schedule2.hiddenID {
                    return false
                } else {
                    return true
                }
            }
        }
    }

    // Function for reading all jobs for schedule and all history of past executions.
    // Schedules are stored in self.schedules. Schedules are sorted after hiddenID.
    func readschedulesjson() {
        if let schedulesfromstore = persistentstorage?.scheduleJSON?.decodedjson {
            let transform = TransformSchedulefromJSON()
            for i in 0 ..< schedulesfromstore.count {
                if let scheduleitem = (schedulesfromstore[i] as? DecodeSchedule), let validhiddenID = self.validhiddenID {
                    var transformed = transform.transform(scheduleitem)
                    transformed.profilename = localprofile
                    if validhiddenID.contains(transformed.hiddenID) {
                        schedules?.append(transformed)
                    }
                }
            }
            // Sorting schedule after hiddenID
            schedules?.sort { (schedule1, schedule2) -> Bool in
                if schedule1.hiddenID > schedule2.hiddenID {
                    return false
                } else {
                    return true
                }
            }
        }
    }

    init(profile: String?, validhiddenIDs: Set<Int>?) {
        localprofile = profile
        schedules = nil
        validhiddenID = validhiddenIDs
        schedules = [ConfigurationSchedule]()
        persistentstorage = PersistentStorage(profile: localprofile,
                                              whattoreadorwrite: .schedule)
        readschedulesjson()
        readschedulesplist()
        if SharedReference.shared.checkinput {
            schedules = Reorgschedule().mergerecords(data: schedules)
        }
    }
}
