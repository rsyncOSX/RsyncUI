//
//  RsyncUIlogrecords.swift
//  RsyncUIlogrecords
//
//  Created by Thomas Evensen on 15/10/2021.
//
// swiftlint:disable line_length

import SwiftUI

struct Readlogsfromstore {
    var profile: String?
    var scheduleData: SchedulesSwiftUI

    init(profile: String? = nil, validhiddenIDs: Set<Int>? = nil) {
        self.profile = profile
        scheduleData = SchedulesSwiftUI(profile: self.profile, validhiddenIDs: validhiddenIDs ?? Set<Int>())
    }
}

final class RsyncUIlogrecords: ObservableObject {
    @Published var logrecordsfromstore: Readlogsfromstore?
    @Published var alllogssorted: [Log]?
    var profile: String?

    // NOT USED
    var schedulesandlogs: [ConfigurationSchedule]?
    // In code because of Schedules which are not yet (or ever) enabled in RsyncUI
    // but code is still in repository. Will decide later (2022?) if Schedules will
    // be enabled in RsyncUI.

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

    func filterlogsbyUUIDs(_ uuids: Set<UUID>) -> [Log]? {
        return alllogssorted?.filter { uuids.contains($0.id) }.sorted(by: \.date, using: >)
    }

    func removerecords(_ uuids: Set<UUID>) {
        print(alllogssorted?.count ?? 0)
        alllogssorted?.removeAll(where: { uuids.contains($0.id) })
        print(alllogssorted?.count ?? 0)
    }

    func update(profile: String?, validhiddenIDs: Set<Int>?) async {
        guard validhiddenIDs != nil else { return }
        self.profile = profile
        if profile == SharedReference.shared.defaultprofile || profile == nil {
            logrecordsfromstore = Readlogsfromstore(profile: nil, validhiddenIDs: validhiddenIDs)
        } else {
            logrecordsfromstore = Readlogsfromstore(profile: profile, validhiddenIDs: validhiddenIDs)
        }
        alllogssorted = logrecordsfromstore?.scheduleData.getalllogs()
    }

    init(profile _: String? = nil, validhiddenIDs _: Set<Int>? = nil) {}
}

/*
 func hasactiveschedules(_ hiddenID: Int) -> Bool {
     let datestopnil = schedulesandlogs?.filter { $0.hiddenID == hiddenID &&
         $0.schedule != Scheduletype.manuel.rawValue &&
         $0.dateStop == nil
     }
     let datestartfuture = schedulesandlogs?.filter { $0.hiddenID == hiddenID &&
         $0.schedule != Scheduletype.manuel.rawValue &&
         $0.dateStart.en_us_date_from_string() > Date()
     }
     let datestopfuture = schedulesandlogs?.filter { $0.hiddenID == hiddenID &&
         $0.schedule != Scheduletype.manuel.rawValue &&
         $0.dateStop?.en_us_date_from_string() ?? Date() > Date()
     }

     return (datestopnil?.count ?? 0 > 0 ||
         datestartfuture?.count ?? 0 > 0 ||
         datestopfuture?.count ?? 0 > 0)
 }
 */
