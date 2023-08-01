//
//  RsyncUIlogrecords.swift
//  RsyncUIlogrecords
//
//  Created by Thomas Evensen on 15/10/2021.
//
// swiftlint:disable line_length

import Observation
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

@Observable
final class RsyncUIlogrecords {
    var alllogssorted: [Log]? = [Log]()
    var scheduleConfigurations: [ConfigurationSchedule]?
    var logrecordsfromstore: Readlogsfromstore?

    func filterlogs(_ filter: String) -> [Log]? {
        // Important - must localize search in dates
        return alllogssorted?.filter {
            filter.isEmpty ? true : $0.dateExecuted?.en_us_date_from_string().long_localized_string_from_date().contains(filter) ?? false ||
                filter.isEmpty ? true : $0.resultExecuted?.contains(filter) ?? false
        }
    }

    func filterlogsbyhiddenID(_ filter: String, _ hiddenID: Int) -> [Log]? {
        guard hiddenID > -1 else { return nil }
        return alllogssorted?.filter { $0.hiddenID == hiddenID }.sorted(by: \.date, using: >).filter {
            filter.isEmpty ? true : $0.dateExecuted?.en_us_date_from_string().long_localized_string_from_date().contains(filter) ?? false ||
                filter.isEmpty ? true : $0.resultExecuted?.contains(filter) ?? false
        }
    }

    func filterlogsbyhiddenID(_ hiddenID: Int) -> [Log]? {
        guard hiddenID > -1 else { return nil }
        return alllogssorted?.filter { $0.hiddenID == hiddenID }.sorted(by: \.date, using: >)
    }

    func removerecords(_ uuids: Set<UUID>) {
        alllogssorted?.removeAll(where: { uuids.contains($0.id) })
    }

    func readlogsfromstore(profile: String?, validhiddenIDs: Set<Int>?) {
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

/*
 extension EnvironmentValues {
     var logrecords: RsyncUIlogrecords {
         get { self[RsyncUIlogrecordsKey.self] }
         set { self[RsyncUIlogrecordsKey.self] = newValue }
     }
 }

 private struct RsyncUIlogrecordsKey: EnvironmentKey {
     static var defaultValue: RsyncUIlogrecords = .init(profile: nil, validhiddenIDs: nil)
 }
 */
// swiftlint:enable line_length
