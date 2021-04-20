//
//  PersistentStorageSchedulingJSON.swift
//  RsyncOSX
//
//  Created by Thomas Evensen on 20/10/2020.
//  Copyright © 2020 Thomas Evensen. All rights reserved.
//
// swiftlint:disable opening_brace

import Foundation

class WriteScheduleJSON: ReadWriteJSON {
    var schedules: [ConfigurationSchedule]?

    // Saving Schedules from MEMORY to persistent store
    func savescheduleInMemoryToPersistentStore() {
        if let schedules: [ConfigurationSchedule] = ConvertSchedules(JSON: true,
                                                                     schedules: self.schedules)
            .cleanedschedules
        {
            writeToStore(schedules: schedules)
        }
    }

    // Writing schedules to persistent store
    private func writeToStore(schedules: [ConfigurationSchedule]?) {
        createJSONfromstructs(schedules: schedules)
        writeJSONToPersistentStore()
    }

    private func createJSONfromstructs(schedules: [ConfigurationSchedule]?) {
        var structscodable: [ConfigurationSchedule]?
        if schedules == nil {
            if let schedules = self.schedules {
                structscodable = [ConfigurationSchedule]()
                for i in 0 ..< schedules.count where schedules[i].delete != true {
                    structscodable?.append(ConfigurationSchedule(schedule: schedules[i]))
                }
            }
        } else {
            if let schedules = schedules {
                structscodable = [ConfigurationSchedule]()
                for i in 0 ..< schedules.count where schedules[i].delete != true {
                    structscodable?.append(ConfigurationSchedule(schedule: schedules[i]))
                }
            }
        }
        jsonstring = encodedata(data: structscodable)
    }

    private func encodedata(data: [ConfigurationSchedule]?) -> String? {
        do {
            let jsonData = try JSONEncoder().encode(data)
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                return jsonString
            }
        } catch let e {
            let error = e
            self.propogateerror(error: error)
            return nil
        }
        return nil
    }

    init(profile: String?,
         schedules: [ConfigurationSchedule]?)
    {
        super.init(profile: profile, whattoreadwrite: .schedule)

        self.schedules = schedules
        self.profile = profile
        createJSONfromstructs(schedules: nil)
        writeconvertedtostore()
    }
}
