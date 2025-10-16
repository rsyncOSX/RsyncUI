//
//  ObservableScheduleData.swift
//  Calendar
//
//  Created by Thomas Evensen on 28/03/2025.
//

import Foundation
import Observation

@Observable @MainActor
final class ObservableScheduleData {
    var scheduledata: [SchedulesConfigurations] = []

    // Verify new planned schedule
    func verifynextschedule(plannednextschedule: String) -> Bool {
        let dates = Array(scheduledata).sorted { s1, s2 in
            if let id1 = s1.dateRun?.en_date_from_string(),
               let id2 = s2.dateRun?.en_date_from_string()
            {
                return id1 < id2
            }
            return false
        }

        if dates.count > 0 {
            // Pick the first schedule
            if let firstschedulestring = dates.first?.dateRun {
                let firstscheduledate = firstschedulestring.en_date_from_string()
                let plannedDate = plannednextschedule.en_date_from_string()

                // Case 1: plannednextschedule is at least 10 minutes AFTER firstscheduledate
                if plannedDate >= firstscheduledate.addingTimeInterval(10 * 60) {
                    return true
                }

                // Case 2: plannednextschedule is between (firstscheduledate - 10 min) and > now
                if plannedDate <= firstscheduledate.addingTimeInterval(-10 * 60),
                   plannedDate > Date.now
                {
                    return true
                }

                return false
            }
        }

        // No schedules added yet
        return plannednextschedule.en_date_from_string() > Date.now
    }

    // Delete by IndexSet
    func delete(_ uuids: Set<UUID>) {
        var indexset = IndexSet()

        _ = scheduledata.map { schedule in
            if let index = scheduledata.firstIndex(of: schedule) {
                if uuids.contains(schedule.id) {
                    indexset.insert(index)
                }
            }
        }
        // Remove all marked configurations in one go by IndexSet
        scheduledata.remove(atOffsets: indexset)
    }

    func removeexecutedonce() {
        scheduledata = scheduledata.compactMap { schedule in
            if let daterun = schedule.dateRun,
               let schedule = schedule.schedule,
               daterun.en_date_from_string() < Date.now,
               schedule == ScheduleType.once.rawValue
            {
                nil
            } else {
                schedule
            }
        }
    }
    
    // Demo for test av schedule
    func demodatatestschedule() {
        let schedule1 = SchedulesConfigurations(profile: nil, dateAdded: Date.now.en_string_from_date(), dateRun: Date.now.addingTimeInterval(60 * 3).en_string_from_date(), schedule: ScheduleType.once.rawValue)
        let schedule2 = SchedulesConfigurations(profile: nil, dateAdded: Date.now.en_string_from_date(), dateRun: Date.now.addingTimeInterval(60 * 4).en_string_from_date(), schedule: ScheduleType.once.rawValue)
        let schedule3 = SchedulesConfigurations(profile: nil, dateAdded: Date.now.en_string_from_date(), dateRun: Date.now.addingTimeInterval(60 * 5).en_string_from_date(), schedule: ScheduleType.once.rawValue)
        let schedule12 = SchedulesConfigurations(profile: nil, dateAdded: Date.now.en_string_from_date(), dateRun: Date.now.addingTimeInterval(60 * 6).en_string_from_date(), schedule: ScheduleType.once.rawValue)
        let schedule22 = SchedulesConfigurations(profile: nil, dateAdded: Date.now.en_string_from_date(), dateRun: Date.now.addingTimeInterval(60 * 7).en_string_from_date(), schedule: ScheduleType.once.rawValue)
        let schedule32 = SchedulesConfigurations(profile: nil, dateAdded: Date.now.en_string_from_date(), dateRun: Date.now.addingTimeInterval(60 * 8).en_string_from_date(), schedule: ScheduleType.once.rawValue)
        scheduledata = [schedule1, schedule2, schedule3, schedule12, schedule22, schedule32]
        
    }

    init() {}
}
