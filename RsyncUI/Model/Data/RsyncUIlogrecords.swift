//
//  RsyncUIlogrecords.swift
//  RsyncUIlogrecords
//
//  Created by Thomas Evensen on 15/10/2021.
//

import Observation
import OSLog

@Observable
final class RsyncUIlogrecords {
    var profile: String?
    var logrecords: [LogRecords]?

    init(_ profile: String?,
         _ validhiddenIDs: Set<Int>?)
    {
        self.profile = profile
        if profile == SharedReference.shared.defaultprofile || profile == nil {
            logrecords = ReadLogRecordsJSON(nil, validhiddenIDs ?? Set()).logrecords
        } else {
            logrecords = ReadLogRecordsJSON(profile, validhiddenIDs ?? Set()).logrecords
        }
    }
}
