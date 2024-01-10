//
//  AllLogs.swift
//  RsyncOSXSwiftUI
//
//  Created by Thomas Evensen on 29/12/2020.
//  Copyright © 2020 Thomas Evensen. All rights reserved.
//

import Foundation

struct AllLogs {
    var logrecords: [LogRecords]?
    var logs: [Log]?

    init(profile: String?, validhiddenIDs: Set<Int>) {
        if profile == SharedReference.shared.defaultprofile || profile == nil {
            let schedulesdata = ReadLogRecordsJSON(nil, validhiddenIDs)
            logrecords = schedulesdata.logrecords?.sorted { log1, log2 in
                log1.dateStart > log2.dateStart
            }
            logs = schedulesdata.logs
        } else {
            let schedulesdata = ReadLogRecordsJSON(profile, validhiddenIDs)
            logrecords = schedulesdata.logrecords?.sorted { log1, log2 in
                log1.dateStart > log2.dateStart
            }
            logs = schedulesdata.logs
        }
    }
}
