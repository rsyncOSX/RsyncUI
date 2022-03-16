//
//  UpdateLogs.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 13/03/2022.
//

import Foundation

final class UpdateLogs {
    private var structschedules: [ConfigurationSchedule]?
    private var localeprofile: String?

    func deletelogs(uuids: Set<UUID>) {
        if let schedules = structschedules {
            var indexset = IndexSet()

            for i in 0 ..< schedules.count {
                for j in 0 ..< uuids.count {
                    if let index = schedules[i].logrecords?.firstIndex(
                        where: { $0.id == uuids[uuids.index(uuids.startIndex, offsetBy: j)] })
                    {
                        indexset.insert(index)
                    }
                }
                structschedules?[i].logrecords?.remove(atOffsets: indexset)
                indexset.removeAll()
            }
            WriteScheduleJSON(localeprofile, structschedules)
        }
    }

    init(profile: String?,
         scheduleConfigurations: [ConfigurationSchedule]?)
    {
        localeprofile = profile
        structschedules = scheduleConfigurations
    }

    deinit {
        // print("deinit UpdateSchedules")
    }
}
