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

    init() {}
}
