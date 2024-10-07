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

    init(_ profile: String?)
    {
        self.profile = profile
        if profile == SharedReference.shared.defaultprofile || profile == nil {
            logrecords = ReadLogRecordsJSON(nil).logrecords
        } else {
            logrecords = ReadLogRecordsJSON(profile).logrecords
        }
    }
}
