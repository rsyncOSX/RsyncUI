//
//  PersistenStorescheduling.swift
//  RsyncOSX
//
//  Created by Thomas Evensen on 02/05/16.
//  Copyright © 2016 Thomas Evensen. All rights reserved.
//
//   Interface between Schedule in memory and
//   presistent store. Class is a interface
//   for Schedule.
//
// swiftlint:disable opening_brace

import Files
import Foundation

class PersistentStorageSchedulingPLIST: ReadWriteDictionary {
    // Variable holds all schedule data from persisten storage
    var schedulesasdictionary: [NSDictionary]?
    var schedules: [ConfigurationSchedule]?

    // Saving Schedules from MEMORY to persistent store
    func savescheduleInMemoryToPersistentStore() {
        if let dicts: [NSDictionary] = ConvertSchedules(JSON: false, schedules: schedules).schedulesNSDictionary {
            writeToStore(array: dicts)
        }
    }

    func writeschedulestostoreasplist() {
        let root = NamesandPaths(profileorsshrootpath: .profileroot)
        if var atpath = root.fullroot {
            if profile != nil {
                atpath += "/" + (profile ?? "")
            }
            savescheduleInMemoryToPersistentStore()
        }
    }

    // Writing schedules to persistent store
    // Schedule is [NSDictionary]
    private func writeToStore(array: [NSDictionary]) {
        if writeNSDictionaryToPersistentStorage(array: array) {}
    }

    init(profile: String?) {
        super.init(profile: profile, whattoreadwrite: .schedule)
        if schedules == nil {
            schedulesasdictionary = readNSDictionaryFromPersistentStore()
        }
    }

    init(profile: String?,
         readonly: Bool,
         schedules: [ConfigurationSchedule]?)
    {
        super.init(profile: profile, whattoreadwrite: .schedule)
        self.schedules = schedules
        if readonly {
            schedulesasdictionary = readNSDictionaryFromPersistentStore()
        } else {
            writeschedulestostoreasplist()
        }
    }
}
