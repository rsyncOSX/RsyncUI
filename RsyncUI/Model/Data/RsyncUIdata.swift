//
//  rsyncUIdata.swift
//  RsyncOSX
//
//  Created by Thomas Evensen on 28/12/2020.
//  Copyright © 2020 Thomas Evensen. All rights reserved.
//
// swiftlint:disable line_length

import SwiftUI

struct Readdatafromstore {
    var profile: String?
    var configurationData: ConfigurationsSwiftUI
    var validhiddenIDs: Set<Int>
    var scheduleData: SchedulesSwiftUI

    init(profile: String?) {
        self.profile = profile
        configurationData = ConfigurationsSwiftUI(profile: self.profile)
        validhiddenIDs = configurationData.getvalidhiddenIDs() ?? Set()
        scheduleData = SchedulesSwiftUI(profile: self.profile, validhiddenIDs: validhiddenIDs)
    }
}

final class RsyncUIdata: ObservableObject {
    @Published var rsyncdata: Readdatafromstore?
    var configurations: [Configuration]?
    var schedulesandlogs: [ConfigurationSchedule]?
    var profile: String?
    var alllogssorted: [Log]?

    func filterlogs(_ filter: String) -> [Log]? {
        // Important - must localize search in dates
        return alllogssorted?.filter {
            filter.isEmpty ? true : $0.dateExecuted?.en_us_date_from_string().long_localized_string_from_date().contains(filter) ?? false ||
                filter.isEmpty ? true : $0.resultExecuted?.contains(filter) ?? false
        }
    }

    func filterlogsbyhiddenID(_ filter: String, _ hiddenID: Int) -> [Log]? {
        var joined: [Log]?
        guard hiddenID > -1 else { return nil }
        let schedulerecords = schedulesandlogs?.filter { $0.hiddenID == hiddenID }
        if (schedulerecords?.count ?? 0) > 0 {
            joined = [Log]()
            for i in 0 ..< (schedulerecords?.count ?? 0) {
                if let logrecords = schedulerecords?[i].logrecords {
                    joined?.append(contentsOf: logrecords)
                }
            }
            return joined?.sorted(by: \.date, using: >).filter {
                filter.isEmpty ? true : $0.dateExecuted?.en_us_date_from_string().long_localized_string_from_date().contains(filter) ?? false ||
                    filter.isEmpty ? true : $0.resultExecuted?.contains(filter) ?? false
            }
        }
        return nil
    }

    func filterlogsbyUUIDs(_ uuids: Set<UUID>) -> [Log]? {
        return alllogssorted?.filter { uuids.contains($0.id) }.sorted(by: \.date, using: >)
    }

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

    func filterconfigurations(_ filter: String) -> [Configuration]? {
        return configurations?.filter {
            filter.isEmpty ? true : $0.backupID.contains(filter)
        }
    }

    init(profile: String?) {
        guard SharedReference.shared.reload == true else {
            SharedReference.shared.reload = true
            return
        }
        self.profile = profile
        if profile == "Default profile" || profile == nil {
            rsyncdata = Readdatafromstore(profile: nil)
        } else {
            rsyncdata = Readdatafromstore(profile: profile)
        }
        configurations = rsyncdata?.configurationData.getallconfigurations()
        schedulesandlogs = rsyncdata?.scheduleData.getschedules()
        alllogssorted = rsyncdata?.scheduleData.getalllogs()
        print("RsyncUIdata \(Unmanaged.passUnretained(self).toOpaque())")
        print("RsyncUIdata configurations  count \(configurations?.count ?? 0)")
        print("RsyncUIdata logrecord count \(alllogssorted?.count ?? 0)")
    }
}
