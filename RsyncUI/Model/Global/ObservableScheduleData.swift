//
//  ObservableScheduleData.swift
//  Calendar
//
//  Created by Thomas Evensen on 28/03/2025.
//

import Foundation
import Observation

enum ValidateDate: LocalizedError {
    case novaliddate
    case previousdate

    var errorDescription: String? {
        switch self {
        case .novaliddate:
            "Date is not valid"
        case .previousdate:
            "Date is not a future date"
        }
    }
}

@Observable @MainActor
final class ObservableScheduleData {
    var scheduledata: [SchedulesConfigurations] = []
    
    
    // At least 10 min between schedules
    func verifynextschedule(nextschedule: String) -> Bool {
        let dates = Array(scheduledata).sorted { s1, s2 in
            if let id1 = s1.dateRun?.en_date_from_string(),
               let id2 = s2.dateRun?.en_date_from_string() {
                return id1 < id2
            }
            return false
        }
        
        if dates.count > 0 {
            if let nextScheduleString = dates.first?.dateRun {
               let nextScheduleDate = nextScheduleString.en_date_from_string()
                let tenMinutesnextScheduleDate = nextScheduleDate.addingTimeInterval(10 * 60)
                
                if nextschedule.en_date_from_string() > tenMinutesnextScheduleDate {
                    return true
                } else {
                    return false
                }
            }
        }
        return true
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

    // Validate input, throws errors
    func validatedate(date: String) throws {
        guard date.isEmpty == false else {
            throw ValidateDate.novaliddate
        }
        guard date.en_date_from_string() > Date.now else {
            throw ValidateDate.previousdate
        }
        if let _ = date.validate_en_date_from_string() {
            return
        } else {
            throw ValidateDate.novaliddate
        }
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

    init() {}
}
