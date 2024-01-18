//
//  ReadLogRecordsfromstore.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 18/01/2024.
//

import Foundation

struct ReadLogRecordsfromstore {
    var logs: [Log]?
    var logrecords: [LogRecords]?

    init(_ profile: String?, _ validhiddenIDs: Set<Int>?) {
        guard validhiddenIDs != nil else { return }
        var logdata: ReadLogRecordsJSON?
        if profile == SharedReference.shared.defaultprofile || profile == nil {
            logdata = ReadLogRecordsJSON(nil, validhiddenIDs ?? Set())
        } else {
            logdata = ReadLogRecordsJSON(profile, validhiddenIDs ?? Set())
        }
        logrecords = logdata?.logrecords?.sorted { log1, log2 in
            log1.dateStart > log2.dateStart
        }
        logs = logdata?.logs
    }
}
