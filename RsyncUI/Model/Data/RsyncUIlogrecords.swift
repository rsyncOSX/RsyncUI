//
//  RsyncUIlogrecords.swift
//  RsyncUIlogrecords
//
//  Created by Thomas Evensen on 15/10/2021.
//
// swiftlint:disable line_length

import Observation
import OSLog
import SwiftUI

struct Readlogsfromstore {
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

@Observable
final class RsyncUIlogrecords {
    var profile: String? = ""
    var alllogssorted: [Log]?
    var countrecords: Int = 0
    var logrecords: [LogRecords]?
    var logrecordsfromstore: Readlogsfromstore?

    func filterlogs(_ filter: String, _ hiddenID: Int) -> [Log] {
        var activelogrecords: [Log]?
        switch hiddenID {
        case -1:
            if filter.isEmpty == false {
                activelogrecords = nil
                activelogrecords = alllogssorted?.filter {
                    $0.dateExecuted?.en_us_date_from_string().long_localized_string_from_date().contains(filter) ?? false ||
                        $0.resultExecuted?.contains(filter) ?? false
                }
                let number = activelogrecords?.count ?? 0
                Logger.process.info("filter ALL logs by \(filter, privacy: .public) - count: \(String(number), privacy: .public)")
                countrecords = number
                return activelogrecords ?? []

            } else {
                let number = alllogssorted?.count ?? 0
                Logger.process.info("ALL logs - count: \(String(number), privacy: .public)")
                countrecords = number
                return alllogssorted ?? []
            }
        default:
            if filter.isEmpty == false {
                activelogrecords = alllogssorted?.filter { $0.hiddenID == hiddenID }.sorted(by: \.date, using: >).filter {
                    $0.dateExecuted?.en_us_date_from_string().long_localized_string_from_date().contains(filter) ?? false ||
                        $0.resultExecuted?.contains(filter) ?? false
                }
                let number = activelogrecords?.count ?? 0
                Logger.process.info("filter logs BY hiddenID and filter by \(filter) - count: \(String(number), privacy: .public)")
                countrecords = number
                return activelogrecords ?? []
            } else {
                activelogrecords = nil
                activelogrecords = alllogssorted?.filter { $0.hiddenID == hiddenID }.sorted(by: \.date, using: >)
                let number = activelogrecords?.count ?? 0
                Logger.process.info("filter logs BY hiddenID - count: \(String(number), privacy: .public)")
                countrecords = number
                return activelogrecords ?? []
            }
        }
    }

    func removerecords(_ uuids: Set<UUID>) {
        alllogssorted?.removeAll(where: { uuids.contains($0.id) })
    }

    init(_ profile: String?,
         _ logrecordsfromstore: [LogRecords]?,
         _ logs: [Log]?)
    {
        self.profile = profile
        logrecords = logrecordsfromstore
        alllogssorted = logs
    }
}

// swiftlint:enable line_length
