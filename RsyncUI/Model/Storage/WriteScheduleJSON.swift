//
//  WriteScheduleJSON.swift
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
        createJSONfromstructs()
        writeJSONToPersistentStore()
        if Running().isrsyncshedulerunning() {
            Notifications().showNotification("Sending reload message to menu app")
            DistributedNotificationCenter.default()
                .postNotificationName(NSNotification.Name(SharedReference.shared.reloadstring),
                                      object: nil, deliverImmediately: true)
        }
    }

    private func createJSONfromstructs() {
        var structscodable: [ConfigurationSchedule]?
        if let schedules = self.schedules {
            structscodable = [ConfigurationSchedule]()
            for i in 0 ..< schedules.count {
                structscodable?.append(ConfigurationSchedule(schedule: schedules[i]))
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

    init(_ profile: String?, _ schedules: [ConfigurationSchedule]?) {
        super.init(profile)
        filename = SharedReference.shared.fileschedulesjson
        self.schedules = schedules
        self.profile = profile
    }
}
