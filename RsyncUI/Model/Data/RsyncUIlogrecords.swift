//
//  RsyncUIlogrecords.swift
//  RsyncUIlogrecords
//
//  Created by Thomas Evensen on 15/10/2021.
//
// swiftlint:disable line_length

import Observation
import OSLog

@Observable
final class RsyncUIlogrecords {
    var profile: String?
    var logrecords: [LogRecords]?

    init(_ profile: String?,
         _ logrecordsfromstore: [LogRecords]?)
    {
        self.profile = profile
        logrecords = logrecordsfromstore
    }
}

// swiftlint:enable line_length
