//
//  RsyncUIlogrecords.swift
//  RsyncUIlogrecords
//
//  Created by Thomas Evensen on 15/10/2021.
//

import Observation
import OSLog

@Observable @MainActor
final class RsyncUIlogrecords {
    var profile: String?
    var logrecords: [LogRecords]?

    init(_ profile: String?,
         _ validhiddenIDs: Set<Int>?)
    {
        self.profile = profile
        if profile == SharedReference.shared.defaultprofile || profile == nil,
           let validhiddenIDs
        {
            logrecords = ReadLogRecordsJSON().readjsonfilelogrecords(nil, validhiddenIDs)
        } else if let validhiddenIDs {
            logrecords = ReadLogRecordsJSON().readjsonfilelogrecords(profile, validhiddenIDs)
        }
    }
}
