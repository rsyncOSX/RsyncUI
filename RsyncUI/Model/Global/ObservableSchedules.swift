//
//  ObservableSchedules.swift
//  Calendar
//
//  Created by Thomas Evensen on 27/03/2025.
//
/* swiftlint:disable function_parameter_count */

import Foundation
import Observation
import OSLog
import SwiftUI

@Observable @MainActor
final class ObservableSchedules {
    let globaltimer = GlobalTimer.shared

    @ObservationIgnored var lastdateinnextmonth: Date?

    private func computefuturedates(profile: String?, schedule: String, dateRun: Date) {
        // Last date in month is NOT set when loading data at startup
        if lastdateinnextmonth == nil {
            lastdateinnextmonth = computelastdateinnextmonth()
        }

        switch schedule {
        case ScheduleType.daily.rawValue:
            computeDailySchedule(profile: profile, dateRun: dateRun)
        case ScheduleType.weekly.rawValue:
            computeWeeklySchedule(profile: profile, dateRun: dateRun)
        case ScheduleType.once.rawValue:
            computeOnceSchedule(profile: profile, dateRun: dateRun)
        default:
            return
        }
    }

    private func computeOnceSchedule(profile: String?, dateRun: Date) {
        guard let lastdateinnextmonth else { return }
        if dateRun.monthInt <= lastdateinnextmonth.monthInt {
            appendfutureschedule(profile: profile, dateRun: dateRun.en_string_from_date(), schedule: ScheduleType.once.rawValue)
        }
    }

    private func computeDailySchedule(profile: String?, dateRun: Date) {
        var dateComponents = DateComponents()
        dateComponents.day = 1
        computeRepeatingSchedule(profile: profile, dateRun: dateRun, dateComponents: dateComponents,
                                 scheduleType: ScheduleType.daily.rawValue)
    }

    private func computeWeeklySchedule(profile: String?, dateRun: Date) {
        var dateComponents = DateComponents()
        dateComponents.day = 7
        computeRepeatingSchedule(profile: profile, dateRun: dateRun, dateComponents: dateComponents,
                                 scheduleType: ScheduleType.weekly.rawValue)
    }

    private func computeRepeatingSchedule(profile: String?, dateRun: Date, dateComponents: DateComponents, scheduleType: String) {
        guard let lastdateinnextmonth else { return }
        let timeInterval: TimeInterval = lastdateinnextmonth.timeIntervalSince(dateRun)
        guard timeInterval > 0 else { return }

        let index = calculateScheduleIndex(timeInterval: timeInterval, dayInterval: dateComponents.day ?? 0)
        appendInitialScheduleIfNeeded(profile: profile, dateRun: dateRun, lastDayOfMonth: lastdateinnextmonth,
                                      scheduleType: scheduleType)

        addFutureSchedules(profile: profile, startDate: dateRun, dateComponents: dateComponents,
                           scheduleType: scheduleType, count: index, lastDayOfMonth: lastdateinnextmonth)
    }

    private func calculateScheduleIndex(timeInterval: TimeInterval, dayInterval: Int) -> Int {
        switch dayInterval {
        case 1:
            Int(timeInterval / (60 * 60 * 24))
        case 7:
            Int(timeInterval / (60 * 60 * 24 * 7))
        default:
            0
        }
    }

    private func appendInitialScheduleIfNeeded(profile: String?, dateRun: Date, lastDayOfMonth: Date, scheduleType: String) {
        if dateRun.monthInt == lastDayOfMonth.monthInt {
            appendfutureschedule(profile: profile, dateRun: dateRun.en_string_from_date(), schedule: scheduleType)
        }
    }

    private func addFutureSchedules(profile: String?, startDate: Date, dateComponents: DateComponents,
                                    scheduleType: String, count: Int, lastDayOfMonth: Date) {
        var computedDateRun: Date = startDate
        for _ in 0 ..< count {
            if let futureDate = Calendar.current.date(byAdding: dateComponents, to: computedDateRun) {
                computedDateRun = futureDate
                if futureDate.monthInt <= lastDayOfMonth.monthInt {
                    appendfutureschedule(profile: profile, dateRun: futureDate.en_string_from_date(), schedule: scheduleType)
                }
            } else {
                Logger.process.warning("ObservableSchedules: Failed to calculate future dates")
            }
        }
    }

    func computelastdateinnextmonth() -> Date? {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month], from: Date())
        if var month = components.month {
            month += 1
            // Request the last day of that month
            components.day = 0 // Setting day to 0 gives the last day of the previous month
            if let baseDate = calendar.date(from: components),
               let lastDayOfNextMonth = calendar.date(byAdding: .month, value: 1, to: baseDate) {
                return lastDayOfNextMonth
            } else {
                return nil
            }
        }
        return nil
    }

    func appendfutureschedule(profile: String?, dateRun: String, schedule: String) {
        guard dateRun.en_date_from_string() >= Date.now else { return }
        let futureschedule = SchedulesConfigurations(profile: profile,
                                                     dateAdded: Date.now.en_string_from_date(),
                                                     dateRun: dateRun,
                                                     schedule: schedule)
        addtaskandcallback(futureschedule)
    }

    // Recompute the calendardata to only show active schedules in row.
    func recomputeschedules() {
        let recomputedschedules = globaltimer.allSchedules.filter { item in
            if let dateRunString = item.scheduledata?.dateRun {
                return dateRunString.en_date_from_string() > Date.now
            }
            return false
        }

        guard recomputedschedules.count > 0 else {
            globaltimer.invalidateAllSchedulesAndTimer()
            globaltimer.firstscheduledate = nil
            return
        }

        for index in 0 ..< recomputedschedules.count {
            if let schedule = recomputedschedules[index].scheduledata?.schedule,
               let dateRun = recomputedschedules[index].scheduledata?.dateRun?.validate_en_date_from_string() {
                computefuturedates(profile: recomputedschedules[index].scheduledata?.profile, schedule: schedule, dateRun: dateRun)
            }
        }

        globaltimer.setfirsscheduledate()
    }

    private func addtaskandcallback(_ schedule: SchedulesConfigurations) {
        // The Callback for Schedule
        let callback: () -> Void = { [weak self] in
            guard let self else { return }
            globaltimer.scheduleNextTimer()
            // Setting profile name will trigger execution
            globaltimer.scheduledprofile = schedule.profile ?? "Default"
            Task {
                // Logging to file that a Schedule is fired
                await ActorLogToFile().logOutput("Schedule",
                                                 ["ObservableSchedules: schedule FIRED for \(schedule.profile ?? "Default")"])
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

    // Apply Scheduledata read from file, used by SidebarMainView
    func appendschdeuldatafromfile(_ schedules: [SchedulesConfigurations]) {
        for index in 0 ..< schedules.count {
            if let schedule = schedules[index].schedule,
               let dateRun = schedules[index].dateRun?.validate_en_date_from_string() {
                computefuturedates(profile: schedules[index].profile, schedule: schedule, dateRun: dateRun)
            }
        }

        globaltimer.setfirsscheduledate()
    }

    // Verify new planned schedule
    func verifynextschedule(plannednextschedule: String) -> Bool {
        let dates = globaltimer.allSchedules.sorted { schedule1, schedule2 in
            if let id1 = schedule1.scheduledata?.dateRun?.en_date_from_string(),
               let id2 = schedule2.scheduledata?.dateRun?.en_date_from_string() {
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
                   plannedDate > Date.now {
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
        globaltimer.allSchedules.removeAll { schedule in
            uuids.contains(schedule.id)
        }
    }

    // Delete by IndexSet
    func deletenotexecuted(_ uuids: Set<UUID>) {
        globaltimer.notExecutedSchedulesafterWakeUp.removeAll { schedule in
            uuids.contains(schedule.id)
        }
    }
}

/* swiftlint:enable function_parameter_count */
