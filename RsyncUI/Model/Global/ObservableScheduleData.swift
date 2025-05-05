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
