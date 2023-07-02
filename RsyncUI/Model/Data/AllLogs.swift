//
//  SchedulesSwiftUI.swift
//  RsyncOSXSwiftUI
//
//  Created by Thomas Evensen on 29/12/2020.
//  Copyright © 2020 Thomas Evensen. All rights reserved.
//

import Foundation

struct AllLogs {
    var scheduleConfigurations: [ConfigurationSchedule]?

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
        if profile == SharedReference.shared.defaultprofile || profile == nil {
            let schedulesdata = ReadScheduleJSON(nil, validhiddenIDs)
            scheduleConfigurations = schedulesdata.schedules?.sorted { log1, log2 in
                log1.dateStart > log2.dateStart
            }
        } else {
            let schedulesdata = ReadScheduleJSON(profile, validhiddenIDs)
            scheduleConfigurations = schedulesdata.schedules?.sorted { log1, log2 in
                log1.dateStart > log2.dateStart
            }
        }
    }
}

extension AllLogs: Hashable {
    static func == (lhs: AllLogs, rhs: AllLogs) -> Bool {
        return lhs.scheduleConfigurations == rhs.scheduleConfigurations
    }
}
