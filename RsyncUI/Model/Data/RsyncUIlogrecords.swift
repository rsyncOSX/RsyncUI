//
//  RsyncUIlogrecords.swift
//  RsyncUIlogrecords
//
//  Created by Thomas Evensen on 15/10/2021.
//
// swiftlint:disable line_length

import OSLog
import SwiftUI

struct Readlogsfromstore {
    var logrecords: [Log]?
    var scheduleConfigurations: [ConfigurationSchedule]?

    init(profile: String?, validhiddenIDs: Set<Int>?) {
        guard validhiddenIDs != nil else { return }
        let alllogs = AllLogs(profile: profile, validhiddenIDs: validhiddenIDs ?? Set<Int>())
        logrecords = alllogs.logrecords
        scheduleConfigurations = alllogs.scheduleConfigurations
    }
}

final class RsyncUIlogrecords: ObservableObject {
    var alllogssorted: [Log]? = [Log]()
    var scheduleConfigurations: [ConfigurationSchedule]?
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
                Logger.process.info("filter ALL logs by \(filter) - count: \(String(number))")
                return activelogrecords ?? []

            } else {
                let number = alllogssorted?.count ?? 0
                Logger.process.info("ALL logs - count: \(String(number))")
                return alllogssorted ?? []
            }
        default:
            if filter.isEmpty == false {
                activelogrecords = alllogssorted?.filter { $0.hiddenID == hiddenID }.sorted(by: \.date, using: >).filter {
                    filter.isEmpty ? true : $0.dateExecuted?.en_us_date_from_string().long_localized_string_from_date().contains(filter) ?? false ||
                        filter.isEmpty ? true : $0.resultExecuted?.contains(filter) ?? false
                }
                let number = activelogrecords?.count ?? 0
                Logger.process.info("filter logs BY hiddenID and filter by \(filter) - count: \(String(number))")
                return activelogrecords ?? []
            } else {
                activelogrecords = nil
                activelogrecords = alllogssorted?.filter { $0.hiddenID == hiddenID }.sorted(by: \.date, using: >)
                let number = activelogrecords?.count ?? 0
                Logger.process.info("filter logs BY hiddenID - count: \(String(number))")
                return activelogrecords ?? []
            }
        }
    }

    func removerecords(_ uuids: Set<UUID>) {
        alllogssorted?.removeAll(where: { uuids.contains($0.id) })
    }

    init(profile: String?, validhiddenIDs: Set<Int>?) {
        guard validhiddenIDs != nil else { return }
        if profile == SharedReference.shared.defaultprofile || profile == nil {
            logrecordsfromstore = Readlogsfromstore(profile: nil, validhiddenIDs: validhiddenIDs)
        } else {
            logrecordsfromstore = Readlogsfromstore(profile: profile, validhiddenIDs: validhiddenIDs)
        }
        alllogssorted = logrecordsfromstore?.logrecords
        scheduleConfigurations = logrecordsfromstore?.scheduleConfigurations
        logrecordsfromstore = nil
    }
}

// swiftlint:enable line_length
