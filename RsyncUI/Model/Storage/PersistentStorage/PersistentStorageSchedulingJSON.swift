//
//  PersistentStorageSchedulingJSON.swift
//  RsyncOSX
//
//  Created by Thomas Evensen on 20/10/2020.
//  Copyright © 2020 Thomas Evensen. All rights reserved.
//
// swiftlint:disable opening_brace

import Foundation

class PersistentStorageSchedulingJSON: ReadWriteJSON {
    var decodedjson: [Any]?
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
        var structscodable: [CodableConfigurationSchedule]?
        if schedules == nil {
            if let schedules = self.schedules {
                structscodable = [CodableConfigurationSchedule]()
                for i in 0 ..< schedules.count where schedules[i].delete != true {
                    structscodable?.append(CodableConfigurationSchedule(schedule: schedules[i]))
                }
            }
        } else {
            if let schedules = schedules {
                structscodable = [CodableConfigurationSchedule]()
                for i in 0 ..< schedules.count where schedules[i].delete != true {
                    structscodable?.append(CodableConfigurationSchedule(schedule: schedules[i]))
                }
            }
        }
        jsonstring = encodedata(data: structscodable)
    }

    private func encodedata(data: [CodableConfigurationSchedule]?) -> String? {
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

    private func decode(jsonfileasstring: String) {
        if let jsonstring = jsonfileasstring.data(using: .utf8) {
            do {
                let decoder = JSONDecoder()
                decodedjson = try decoder.decode([DecodeSchedule].self, from: jsonstring)
            } catch let e {
                let error = e
                self.propogateerror(error: error)
            }
        }
    }

    func JSONFromPersistentStore() {
        do {
            if let jsonfile = try readJSONFromPersistentStore() {
                guard jsonfile.isEmpty == false else { return }
                decode(jsonfileasstring: jsonfile)
            }
        } catch let e {
            let error = e
            self.propogateerror(error: error)
        }
    }

    init(profile: String?) {
        super.init(profile: profile, whattoreadwrite: .schedule)
        self.profile = profile
        if schedules == nil {
            JSONFromPersistentStore()
        }
    }

    init(profile: String?,
         readonly: Bool,
         schedules: [ConfigurationSchedule]?)
    {
        super.init(profile: profile, whattoreadwrite: .schedule)

        self.schedules = schedules
        self.profile = profile
        if readonly {
            JSONFromPersistentStore()
        } else {
            createJSONfromstructs(schedules: nil)
            writeconvertedtostore()
        }
    }
}
