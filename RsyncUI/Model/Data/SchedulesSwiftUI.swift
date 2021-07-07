//
//  SchedulesSwiftUI.swift
//  RsyncOSXSwiftUI
//
//  Created by Thomas Evensen on 29/12/2020.
//  Copyright © 2020 Thomas Evensen. All rights reserved.
//

import Foundation

struct SchedulesSwiftUI {
    private var scheduleConfigurations: [ConfigurationSchedule]?
    private var profile: String?

    // Return reference to Schedule data
    func getschedules() -> [ConfigurationSchedule] {
        return scheduleConfigurations ?? []
    }

    func getalllogs() -> [Log]? {
        var joined: [Log]?
        let schedulerecords = scheduleConfigurations
        if (schedulerecords?.count ?? 0) > 0 {
            joined = [Log]()
            for i in 0 ..< (schedulerecords?.count ?? 0) {
                if let logrecords = schedulerecords?[i].logrecords {
                    joined?.append(contentsOf: logrecords)
                }
            }
            if let joined = joined {
                return joined.sorted(by: \.date, using: >)
            }
        }
        return nil
    }

    init(profile: String?, validhiddenIDs: Set<Int>) {
        self.profile = profile
        let schedulesdata = ReadScheduleJSON(profile, validhiddenIDs)
        scheduleConfigurations = schedulesdata.schedules?.sorted { log1, log2 in
            log1.dateStart > log2.dateStart
        }
        print("SchedulesSwiftUI")
    }
}

extension SchedulesSwiftUI: Hashable {
    static func == (lhs: SchedulesSwiftUI, rhs: SchedulesSwiftUI) -> Bool {
        return lhs.scheduleConfigurations == rhs.scheduleConfigurations
    }
}
