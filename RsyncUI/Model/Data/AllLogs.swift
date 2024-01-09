//
//  AllLogs.swift
//  RsyncOSXSwiftUI
//
//  Created by Thomas Evensen on 29/12/2020.
//  Copyright © 2020 Thomas Evensen. All rights reserved.
//

import Foundation

struct AllLogs {
    var scheduleConfigurations: [LogRecords]?
    var logrecords: [Log]?

    init(profile: String?, validhiddenIDs: Set<Int>) {
        if profile == SharedReference.shared.defaultprofile || profile == nil {
            let schedulesdata = ReadScheduleJSON(nil, validhiddenIDs)
            scheduleConfigurations = schedulesdata.schedules?.sorted { log1, log2 in
                log1.dateStart > log2.dateStart
            }
            logrecords = schedulesdata.logrecords
        } else {
            let schedulesdata = ReadScheduleJSON(profile, validhiddenIDs)
            scheduleConfigurations = schedulesdata.schedules?.sorted { log1, log2 in
                log1.dateStart > log2.dateStart
            }
            logrecords = schedulesdata.logrecords
        }
    }
}
