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
            let logdata = ReadLogRecordsJSON(nil, validhiddenIDs)
            logrecords = logdata.logrecords?.sorted { log1, log2 in
                log1.dateStart > log2.dateStart
            }
            logs = logdata.logs
        } else {
            let logdata = ReadLogRecordsJSON(profile, validhiddenIDs)
            logrecords = logdata.logrecords?.sorted { log1, log2 in
                log1.dateStart > log2.dateStart
            }
            logs = logdata.logs
        }
    }
}
