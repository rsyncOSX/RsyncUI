//
//  ObservableSchedulesDEMO.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 20/10/2025.
//

//
//  ObservableSchedulesDEMO.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 20/10/2025.
//

import Foundation
import Observation
import OSLog
import SwiftUI

@Observable @MainActor
final class ObservableSchedulesDEMO {
    let globaltime = GlobalTimer.shared

    @ObservationIgnored var lastdateinpresentmont: Date?

    // var scheduledata: [SchedulesConfigurations]?
    // First schedule to execute
    var firstscheduledate: SchedulesConfigurations?
    // Trigger execution
    var scheduledprofile: String = ""

    private func computefuturedates(profile: String?, schedule: String, dateRun: Date) {
        var dateComponents = DateComponents()

        // Last date in month is NOT set when loading data at startup
        if lastdateinpresentmont == nil {
            lastdateinpresentmont = Date.now.endOfMonth
        }

        switch schedule {
        case ScheduleType.daily.rawValue:
            dateComponents.day = 1
        /*
         case ScheduleType.weekly.rawValue:
             dateComponents.day = 7
          */
        case ScheduleType.once.rawValue:
            // Handle once as a special case, only daily and weekly needs repeat
            if let lastdateinpresentmont {
                if dateRun.monthInt == lastdateinpresentmont.monthInt {
                    appendfutureschedule(profile: profile, dateRun: dateRun.en_string_from_date(), schedule: ScheduleType.once.rawValue)
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
                    appendfutureschedule(profile: profile, dateRun: dateRun.en_string_from_date(), schedule: ScheduleType.daily.rawValue)
                }
            /*
             case 7:
                 index = Int(timeInterval / (60 * 60 * 24 * 7))
                 // Must add the first registered date as well
                 if dateRun.monthInt == lastdateinpresentmont.monthInt {
                     appendfutureschedule(profile: profile, dateRun: dateRun.en_string_from_date(), schedule: "")
                 }
              */
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
                        appendfutureschedule(profile: profile, dateRun: futureDateString, schedule: ScheduleType.daily.rawValue)
                    }

                } else {
                    Logger.process.warning("ObservableFutureSchedules: Failed to calculate future dates")
                }
            }
            let count = globaltime.allSchedules.count
            Logger.process.info("ObservableFutureSchedules: private computefuturedates(): (\(count))")
        }
    }

    // CAUTION: check for DEMO mode or not
    func appendfutureschedule(profile: String?, dateRun: String, schedule: String) {
        // DEMO mode
        guard dateRun.en_date_from_string() >= Date.now else { return }
        let futureschedule = SchedulesConfigurations(profile: profile,
                                                     dateAdded: Date.now.en_string_from_date(),
                                                     dateRun: dateRun,
                                                     schedule: schedule)
        adddemotaskandcallback(futureschedule)
    }

    // Recompute the calendardata to only show active schedules in row.
    func recomputeschedules() {
        Logger.process.info("ObservableFutureSchedules: recomputeschedules()")
        let recomputedschedules = globaltime.allSchedules.filter { item in
            if let dateRunString = item.scheduledata?.dateRun {
                return dateRunString.en_date_from_string() > Date.now
            }
            return false
        }

        guard recomputedschedules.count > 0 else {
            GlobalTimer.shared.invalidateAllSchedulesAndTimer()
            firstscheduledate = nil
            Logger.process.info("ObservableFutureSchedules: recomputeschedules() no schdeules")

            return
        }

        Logger.process.info("ObservableFutureSchedules: recomputeschedules() number of schedules: \(recomputedschedules.count, privacy: .public)")

        for i in 0 ..< recomputedschedules.count {
            if let schedule = recomputedschedules[i].scheduledata?.schedule,
               let dateRun = recomputedschedules[i].scheduledata?.dateRun?.validate_en_date_from_string()
            {
                computefuturedates(profile: recomputedschedules[i].scheduledata?.profile, schedule: schedule, dateRun: dateRun)
            }
        }

        setfirsscheduledate()
    }

    // Only set when loading data, when new schedules added or deleted
    private func setfirsscheduledate() {
        let dates = globaltime.allSchedules.sorted { s1, s2 in
            if let id1 = s1.scheduledata?.dateRun?.en_date_from_string(), let id2 = s2.scheduledata?.dateRun?.en_date_from_string() {
                return id1 < id2
            }
            return false
        }
        if dates.count > 0 {
            let first = SchedulesConfigurations(profile: dates.first?.scheduledata?.profile,
                                                dateAdded: nil,
                                                dateRun: dates.first?.scheduledata?.dateRun,
                                                schedule: "")
            firstscheduledate = first
        } else {
            firstscheduledate = nil
        }
    }

    // Verify new planned schedule
    func verifynextschedule(plannednextschedule: String) -> Bool {
        let dates = globaltime.allSchedules.sorted { s1, s2 in
            if let id1 = s1.scheduledata?.dateRun?.en_date_from_string(),
               let id2 = s2.scheduledata?.dateRun?.en_date_from_string()
            {
                return id1 < id2
            }
            return false
        }

        if dates.count > 0 {
            // Pick the first schedule
            if let firstschedulestring = dates.first?.scheduledata?.dateRun {
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
        globaltime.allSchedules.removeAll { schedule in
            uuids.contains(schedule.id)
        }
    }

    // Delete by IndexSet
    func deletenotexecuted(_ uuids: Set<UUID>) {
        globaltime.notExecutedSchedulesafterWakeUp.removeAll { schedule in
            uuids.contains(schedule.id)
        }
    }

    // Demo for test av schedule
    func demodatatestschedule() {
        // Must set demo = true to stop trigger for SidebarMainView
        let schedule1 = SchedulesConfigurations(profile: nil, dateAdded: Date.now.en_string_from_date(), dateRun: Date.now.addingTimeInterval(60 * 10).en_string_from_date(), schedule: ScheduleType.once.rawValue)
        let schedule2 = SchedulesConfigurations(profile: nil, dateAdded: Date.now.en_string_from_date(), dateRun: Date.now.addingTimeInterval(60 * 15).en_string_from_date(), schedule: ScheduleType.once.rawValue)
        let schedule3 = SchedulesConfigurations(profile: nil, dateAdded: Date.now.en_string_from_date(), dateRun: Date.now.addingTimeInterval(60 * 20).en_string_from_date(), schedule: ScheduleType.once.rawValue)
        let schedule4 = SchedulesConfigurations(profile: nil, dateAdded: Date.now.en_string_from_date(), dateRun: Date.now.addingTimeInterval(60 * 25).en_string_from_date(), schedule: ScheduleType.once.rawValue)
        let schedule5 = SchedulesConfigurations(profile: nil, dateAdded: Date.now.en_string_from_date(), dateRun: Date.now.addingTimeInterval(60 * 30).en_string_from_date(), schedule: ScheduleType.once.rawValue)
        let schedule6 = SchedulesConfigurations(profile: nil, dateAdded: Date.now.en_string_from_date(), dateRun: Date.now.addingTimeInterval(60 * 35).en_string_from_date(), schedule: ScheduleType.once.rawValue)

        let scheduledata = [schedule1, schedule2, schedule3, schedule4, schedule5, schedule6]
        // let scheduledata = [schedule1, schedule2, schedule3]
        let deleteschedule1 = SchedulesConfigurations(profile: nil, dateAdded: Date.now.en_string_from_date(), dateRun: Date.now.addingTimeInterval(-60).en_string_from_date(), schedule: ScheduleType.daily.rawValue)
        let deleteschedule2 = SchedulesConfigurations(profile: nil, dateAdded: Date.now.en_string_from_date(), dateRun: Date.now.addingTimeInterval(-60 * 2).en_string_from_date(), schedule: ScheduleType.daily.rawValue)
        let deleteschedule3 = SchedulesConfigurations(profile: nil, dateAdded: Date.now.en_string_from_date(), dateRun: Date.now.addingTimeInterval(-60 * 3).en_string_from_date(), schedule: ScheduleType.daily.rawValue)
        let deleteschedule4 = SchedulesConfigurations(profile: nil, dateAdded: Date.now.en_string_from_date(), dateRun: Date.now.addingTimeInterval(-60 * 4).en_string_from_date(), schedule: ScheduleType.daily.rawValue)

        // Demodata
        for i in 0 ..< scheduledata.count {
            if let schedule = scheduledata[i].schedule,
               let dateRun = scheduledata[i].dateRun?.validate_en_date_from_string()
            {
                computefuturedates(profile: scheduledata[i].profile, schedule: schedule, dateRun: dateRun)
            }
        }
        // Insert data in not executed table (for demo an test)

        setfirsscheduledate()

        // Not executed table

        let schedulenotexecuted = [deleteschedule1, deleteschedule2, deleteschedule3, deleteschedule4]
        let callback: () -> Void = { [weak self] in
            guard self != nil else { return }
            GlobalTimer.shared.scheduleNextTimer()
            Task {
                // Logging to file that a Schedule is fired
                await ActorLogToFile(command: "Schedule", stringoutputfromrsync: ["ObservableFutureSchedules: schedule NOTEXECUTED for DEMO:"])
            }
        }

        for i in 0 ..< schedulenotexecuted.count {
            // Then add new schedule
            if let schedultime = schedulenotexecuted[i].dateRun?.en_date_from_string() {
                adddemotasknotexecuted(time: schedultime,
                                       tolerance: 10,
                                       callback: callback,
                                       scheduledata: schedulenotexecuted[i])
            }
        }
    }

    // Demo tasks

    private func adddemotaskandcallback(_ schedule: SchedulesConfigurations) {
        Logger.process.info("ObservableFutureSchedules: addtaskandcallback() adding DEMO schedule")
        let globaltimer = GlobalTimer.shared

        let count = globaltime.allSchedules.count
        let callback: () -> Void = { [weak self] in
            guard self != nil else { return }
            GlobalTimer.shared.scheduleNextTimer()
            Task {
                // Logging to file that a Schedule is fired
                await ActorLogToFile(command: "Schedule", stringoutputfromrsync: ["ObservableFutureSchedules: schedule FIRED for DEMO: count is \(count)"])
            }
        }
        // Then add new schedule
        if let schedultime = schedule.dateRun?.en_date_from_string() {
            globaltimer.addSchedule(time: schedultime,
                                    tolerance: 10,
                                    callback: callback,
                                    scheduledata: schedule)
        }
    }

    private func adddemotasknotexecuted(time: Date,
                                        tolerance: TimeInterval? = nil,
                                        callback: @escaping () -> Void,
                                        scheduledata: SchedulesConfigurations?)
    {
        let globaltimer = GlobalTimer.shared
        let interval = time.timeIntervalSince(.now)
        let finalTolerance = tolerance ?? globaltimer.defaultTolerance(for: interval)

        let scheduleitem = ScheduledItem(
            time: time,
            tolerance: max(0, finalTolerance),
            callback: callback,
            scheduledata: scheduledata
        )
        // Append and sort by time
        globaltimer.notExecutedSchedulesafterWakeUp.append(scheduleitem)
        globaltimer.notExecutedSchedulesafterWakeUp = globaltimer.notExecutedSchedulesafterWakeUp.sorted(by: { $0.time < $1.time })
    }
}
