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

    private func computefuturedates(profile: String, schedule: String, dateRun: Date, dateStop: Date?) {
        var dateComponents = DateComponents()

        switch schedule {
        case ScheduleType.daily.rawValue:
            dateComponents.day = 1
        case ScheduleType.weekly.rawValue:
            dateComponents.day = 7
        case ScheduleType.once.rawValue:
            // Handle once as a specail case, only daily and weekly needs repeat
            if let lastdateinpresentmont {
                if dateRun.monthInt == lastdateinpresentmont.monthInt {
                    appendfutureschedule(profile: profile, dateRun: dateRun.en_us_string_from_date())
                }
            }
            return
        case ScheduleType.stopped.rawValue:
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
                    appendfutureschedule(profile: profile, dateRun: dateRun.en_us_string_from_date())
                }
            case 7:
                index = Int(timeInterval / (60 * 60 * 24 * 7))
                // Must add the first registered date as well
                if dateRun.monthInt == lastdateinpresentmont.monthInt {
                    appendfutureschedule(profile: profile, dateRun: dateRun.en_us_string_from_date())
                }
            default:
                break
            }
            // Loops only for daily and weekly
            for _ in 0 ..< index {
                if let futureDate = Calendar.current.date(byAdding: dateComponents, to: computedDateRun) {
                    let futureDateString = futureDate.en_us_string_from_date()
                    // Set computedDateRun to next futureDate, adding dateComponents will compute
                    // the next futureDate again.
                    computedDateRun = futureDate
                    // Only add futuredates in month presented, also chech if there is a datStop
                    if let dateStop {
                        if futureDate.monthInt == lastdateinpresentmont.monthInt && futureDate <= dateStop {
                            appendfutureschedule(profile: profile, dateRun: futureDateString)
                        }
                    } else {
                        if futureDate.monthInt == lastdateinpresentmont.monthInt {
                            appendfutureschedule(profile: profile, dateRun: futureDateString)
                        }
                    }
                   
                } else {
                    
                    Logger.process.warning("ObservableFutureSchedules: Failed to calculate future dates")
                }
            }
            let count = futureschedules.count
            Logger.process.info("ObservableFutureSchedules: private computefuturedates(): (\(count))")
        }
    }

    private func appendfutureschedule(profile: String, dateRun: String) {
        let schedule = SchedulesConfigurations(profile: profile,
                                               dateAdded: nil,
                                               dateRun: dateRun,
                                               dateStop: nil,
                                               schedule: profile)
        futureschedules.insert(schedule)
    }

    func recomputeschedules() {
        Logger.process.info("ObservableFutureSchedules: recomputeschedules()")

        futureschedules.removeAll()

        if let scheduledata {
            for i in 0 ..< scheduledata.count {
                let profile = scheduledata[i].profile ?? ""
                let schedule = scheduledata[i].schedule ?? ScheduleType.stopped.rawValue
                let dateRun = scheduledata[i].dateRun?.en_us_date_from_string() ?? Date()
                let dateStop = scheduledata[i].dateStop?.en_us_date_from_string() ?? Date()

                computefuturedates(profile: profile, schedule: schedule, dateRun: dateRun, dateStop: dateStop)
            }
        }
    }
}
