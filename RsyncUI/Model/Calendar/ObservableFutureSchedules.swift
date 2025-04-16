//
//  ObservableFutureSchedules.swift
//  Calendar
//
//  Created by Thomas Evensen on 27/03/2025.
//

import Foundation
import Observation
import OSLog

@Observable @MainActor
final class ObservableFutureSchedules {
    @ObservationIgnored var futureschedules = Set<SchedulesConfigurations>()
    @ObservationIgnored var lastdateinpresentmont: Date?
    @ObservationIgnored var scheduledata: [SchedulesConfigurations]?
    // First schedule to execute
    @ObservationIgnored var firstscheduledate: SchedulesConfigurations?

    private func computefuturedates(profile: String, schedule: String, dateRun: Date) {
        var dateComponents = DateComponents()
        
        // Last date in month is NOT set when loading data at startup
        if lastdateinpresentmont == nil {
            lastdateinpresentmont = Date.now.endOfMonth
        }

        switch schedule {
        case ScheduleType.daily.rawValue:
            dateComponents.day = 1
        case ScheduleType.weekly.rawValue:
            dateComponents.day = 7
        case ScheduleType.once.rawValue:
            // Handle once as a special case, only daily and weekly needs repeat
            if let lastdateinpresentmont {
                if dateRun.monthInt == lastdateinpresentmont.monthInt {
                    appendfutureschedule(profile: profile, dateRun: dateRun.en_string_from_date(), schedule: "")
                }
            }
            return
        default:
            return
        }
        // This date is incrementet by schedule
        var computedDateRun: Date = dateRun
        
        if let lastdateinpresentmont {
            let timeInterval: TimeInterval = lastdateinpresentmont.timeIntervalSince(computedDateRun)

            guard timeInterval > 0 else { return }

            var index = 0

            switch dateComponents.day ?? 0 {
            case 1:
                index = Int(timeInterval / (60 * 60 * 24))
                // Must add the first registered date as well
                if dateRun.monthInt == lastdateinpresentmont.monthInt {
                    appendfutureschedule(profile: profile, dateRun: dateRun.en_string_from_date(), schedule: "")
                }
            case 7:
                index = Int(timeInterval / (60 * 60 * 24 * 7))
                // Must add the first registered date as well
                if dateRun.monthInt == lastdateinpresentmont.monthInt {
                    appendfutureschedule(profile: profile, dateRun: dateRun.en_string_from_date(), schedule: "")
                }
            default:
                break
            }
            // Loops only for daily and weekly
            for _ in 0 ..< index {
                if let futureDate = Calendar.current.date(byAdding: dateComponents, to: computedDateRun) {
                    let futureDateString = futureDate.en_string_from_date()
                    // Set computedDateRun to next futureDate, adding dateComponents will compute
                    // the next futureDate again.
                    computedDateRun = futureDate
                    // Only add futuredates in month presented
                    if futureDate.monthInt == lastdateinpresentmont.monthInt {
                        appendfutureschedule(profile: profile, dateRun: futureDateString, schedule: "")
                    }

                } else {
                    Logger.process.warning("ObservableFutureSchedules: Failed to calculate future dates")
                }
            }
            let count = futureschedules.count
            Logger.process.info("ObservableFutureSchedules: private computefuturedates(): (\(count))")
        }
    }

    private func appendfutureschedule(profile: String, dateRun: String, schedule: String) {
        // Only add futuredates
        guard dateRun.en_date_from_string() >= Date.now else { return }
        let futureschedule = SchedulesConfigurations(profile: profile,
                                                     dateAdded: nil,
                                                     dateRun: dateRun,
                                                     schedule: schedule)
        futureschedules.insert(futureschedule)
    }

    func recomputeschedules() {
        Logger.process.info("ObservableFutureSchedules: recomputeschedules()")

        futureschedules.removeAll()

        if let scheduledata {
            for i in 0 ..< scheduledata.count {
                if let profile = scheduledata[i].profile,
                   let schedule = scheduledata[i].schedule,
                   let dateRun = scheduledata[i].dateRun?.validate_en_date_from_string() {
                    computefuturedates(profile: profile, schedule: schedule, dateRun: dateRun)
                }
            }
        }
    }

    // Only set when loading data, when new schedules added or deleted
    func setfirsscheduledate() {
        let dates = Array(futureschedules).sorted { s1, s2 in
            if let id1 = s1.dateRun?.en_date_from_string(), let id2 = s2.dateRun?.en_date_from_string() {
                return id1 < id2
            }
            return false
        }
        if dates.count > 0 {
            let first = SchedulesConfigurations(profile: dates.first?.profile,
                                                dateAdded: nil,
                                                dateRun: dates.first?.dateRun,
                                                schedule: "")

            firstscheduledate = first
        }
    }
}
