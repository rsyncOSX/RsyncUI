//
//  ObservableSchedules.swift
//  Calendar
//
//  Created by Thomas Evensen on 27/03/2025.
//

import Foundation
import Observation
import OSLog
import SwiftUI

@Observable @MainActor
final class ObservableSchedules {
    let globaltimer = GlobalTimer.shared

    @ObservationIgnored var lastdateinnextmonth: Date?
    private(set) var scheduleDefinitions = [SchedulesConfigurations]()

    private func computefuturedates(profile: String?, schedule: String, dateRun: Date, definitionID: UUID) {
        if lastdateinnextmonth == nil {
            lastdateinnextmonth = computelastdateinnextmonth()
        }

        switch schedule {
        case ScheduleType.daily.rawValue:
            computeDailySchedule(profile: profile, dateRun: dateRun, definitionID: definitionID)
        case ScheduleType.weekly.rawValue:
            computeWeeklySchedule(profile: profile, dateRun: dateRun, definitionID: definitionID)
        case ScheduleType.once.rawValue:
            computeOnceSchedule(profile: profile, dateRun: dateRun, definitionID: definitionID)
        default:
            return
        }
    }

    private func computeOnceSchedule(profile: String?, dateRun: Date, definitionID: UUID) {
        guard dateRun <= schedulingHorizon else { return }
        appendScheduleOccurrence(id: definitionID,
                                 profile: profile,
                                 dateRun: dateRun.en_string_from_date(),
                                 schedule: ScheduleType.once.rawValue)
    }

    private func computeDailySchedule(profile: String?, dateRun: Date, definitionID: UUID) {
        var dateComponents = DateComponents()
        dateComponents.day = 1
        computeRepeatingSchedule(
            definitionID: definitionID,
            profile: profile,
            dateRun: dateRun,
            dateComponents: dateComponents,
            scheduleType: ScheduleType.daily.rawValue
        )
    }

    private func computeWeeklySchedule(profile: String?, dateRun: Date, definitionID: UUID) {
        var dateComponents = DateComponents()
        dateComponents.day = 7
        computeRepeatingSchedule(
            definitionID: definitionID,
            profile: profile,
            dateRun: dateRun,
            dateComponents: dateComponents,
            scheduleType: ScheduleType.weekly.rawValue
        )
    }

    private func computeRepeatingSchedule(definitionID: UUID, profile: String?, dateRun: Date,
                                          dateComponents: DateComponents, scheduleType: String) {
        let timeInterval: TimeInterval = schedulingHorizon.timeIntervalSince(dateRun)
        guard timeInterval > 0 else { return }

        let index = calculateScheduleIndex(timeInterval: timeInterval, dayInterval: dateComponents.day ?? 0)
        appendInitialScheduleIfNeeded(
            definitionID: definitionID,
            profile: profile,
            dateRun: dateRun,
            lastDayOfMonth: schedulingHorizon,
            scheduleType: scheduleType
        )

        addFutureSchedules(
            definitionID: definitionID,
            profile: profile,
            startDate: dateRun,
            dateComponents: dateComponents,
            scheduleType: scheduleType,
            count: index,
            lastDayOfMonth: schedulingHorizon
        )
    }

    private func calculateScheduleIndex(timeInterval: TimeInterval, dayInterval: Int) -> Int {
        switch dayInterval {
        case 1:
            return Int(timeInterval / (60 * 60 * 24))
        case 7:
            return Int(timeInterval / (60 * 60 * 24 * 7))
        default:
            Logger.process.warning("ObservableSchedules: unhandled dayInterval \(dayInterval), returning 0")
            return 0
        }
    }

    private func appendInitialScheduleIfNeeded(definitionID: UUID, profile: String?, dateRun: Date,
                                               lastDayOfMonth: Date, scheduleType: String) {
        if dateRun >= Date.now, dateRun <= lastDayOfMonth {
            appendScheduleOccurrence(id: definitionID,
                                     profile: profile,
                                     dateRun: dateRun.en_string_from_date(),
                                     schedule: scheduleType)
        }
    }

    private func addFutureSchedules(definitionID: UUID, profile: String?, startDate: Date, dateComponents: DateComponents,
                                    scheduleType: String, count: Int, lastDayOfMonth: Date) {
        var computedDateRun: Date = startDate
        for _ in 0 ..< count {
            if let futureDate = Calendar.current.date(byAdding: dateComponents, to: computedDateRun) {
                computedDateRun = futureDate
                if futureDate <= lastDayOfMonth {
                    appendScheduleOccurrence(id: definitionID,
                                             profile: profile,
                                             dateRun: futureDate.en_string_from_date(),
                                             schedule: scheduleType)
                }
            } else {
                Logger.process.warning("ObservableSchedules: Failed to calculate future dates")
            }
        }
    }

    func computelastdateinnextmonth() -> Date? {
        let calendar = Calendar.current
        guard let nextMonth = calendar.date(byAdding: .month, value: 1, to: Date()),
              let interval = calendar.dateInterval(of: .month, for: nextMonth),
              let lastSecondOfNextMonth = calendar.date(byAdding: .second, value: -1, to: interval.end)
        else { return nil }
        return lastSecondOfNextMonth
    }

    func appendSchedule(profile: String?, dateRun: String, schedule: String) -> Bool {
        guard let plannedDate = validPlannedScheduleDate(dateRun) else { return false }
        let scheduleDefinition = SchedulesConfigurations(profile: profile,
                                                         dateAdded: Date.now.en_string_from_date(),
                                                         dateRun: plannedDate.en_string_from_date(),
                                                         schedule: schedule)
        guard scheduleDefinitions.contains(where: { sameScheduleDefinition($0, scheduleDefinition) }) == false else { return false }
        scheduleDefinitions.append(scheduleDefinition)
        recomputeschedules()
        return true
    }

    func appendScheduleOccurrence(id: UUID, profile: String?, dateRun: String, schedule: String) {
        guard let parsedDate = dateRun.validate_en_date_from_string(), parsedDate >= Date.now else { return }
        let futureschedule = SchedulesConfigurations(id: id,
                                                     profile: profile,
                                                     dateAdded: Date.now.en_string_from_date(),
                                                     dateRun: parsedDate.en_string_from_date(),
                                                     schedule: schedule)
        addtaskandcallback(futureschedule)
    }

    func scheduleDataForPersistence() -> [SchedulesConfigurations] {
        scheduleDefinitions.filter { definition in
            guard let schedule = definition.schedule,
                  let dateRun = definition.dateRun?.validate_en_date_from_string()
            else { return false }
            if schedule == ScheduleType.once.rawValue {
                return dateRun > Date.now
            }
            return dateRun <= schedulingHorizon
        }
    }

    /// Recompute the calendardata to only show active schedules in row.
    func recomputeschedules() {
        scheduleDefinitions = scheduleDataForPersistence()

        guard scheduleDefinitions.isEmpty == false else {
            globaltimer.invalidateAllSchedulesAndTimer()
            globaltimer.firstscheduledate = nil
            return
        }

        globaltimer.invalidateAllSchedulesAndTimer()

        for index in 0 ..< scheduleDefinitions.count {
            if let schedule = scheduleDefinitions[index].schedule,
               let dateRun = scheduleDefinitions[index].dateRun?.validate_en_date_from_string() {
                computefuturedates(profile: scheduleDefinitions[index].profile,
                                   schedule: schedule,
                                   dateRun: dateRun,
                                   definitionID: scheduleDefinitions[index].id)
            }
        }

        globaltimer.refreshTimerAfterScheduleMutation()
    }

    private func addtaskandcallback(_ schedule: SchedulesConfigurations) {
        let callback: () -> Void = { [weak self] in
            guard let self else { return }
            globaltimer.scheduleNextTimer()
            globaltimer.scheduledprofile = schedule.profile ?? "Default"
            Task {
                await ActorLogToFile.shared.logOutput("Schedule",
                                                      ["ObservableSchedules: schedule FIRED for \(schedule.profile ?? "Default")"])
            }
        }
        if let schedultime = schedule.dateRun?.validate_en_date_from_string() {
            globaltimer.addSchedule(time: schedultime,
                                    tolerance: 10,
                                    callback: callback,
                                    scheduledata: schedule)
        }
    }

    /// Apply Scheduledata read from file, used by SidebarMainView
    func appendschdeuldatafromfile(_ schedules: [SchedulesConfigurations]) {
        scheduleDefinitions = uniquedScheduleDefinitions(schedules).filter { definition in
            guard let schedule = definition.schedule,
                  let dateRun = definition.dateRun?.validate_en_date_from_string()
            else { return false }
            if schedule == ScheduleType.once.rawValue {
                return dateRun > Date.now
            }
            return dateRun <= schedulingHorizon
        }
        recomputeschedules()
    }

    /// Verify new planned schedule
    func verifynextschedule(plannednextschedule: String) -> Bool {
        guard let plannedDate = validPlannedScheduleDate(plannednextschedule) else { return false }

        let dates = globaltimer.allSchedules.sorted { schedule1, schedule2 in
            if let id1 = schedule1.scheduledata?.dateRun?.validate_en_date_from_string(),
               let id2 = schedule2.scheduledata?.dateRun?.validate_en_date_from_string() {
                return id1 < id2
            }
            return false
        }

        if dates.count > 0 {
            if let firstschedulestring = dates.first?.scheduledata?.dateRun,
               let firstscheduledate = firstschedulestring.validate_en_date_from_string() {
                if plannedDate >= firstscheduledate.addingTimeInterval(10 * 60) {
                    return true
                }

                if plannedDate <= firstscheduledate.addingTimeInterval(-10 * 60),
                   plannedDate > Date.now {
                    return true
                }

                return false
            }
        }

        return plannedDate > Date.now
    }

    func validPlannedScheduleDate(_ plannednextschedule: String) -> Date? {
        guard let plannedDate = plannednextschedule.validate_en_date_from_string(),
              plannedDate > Date.now,
              plannedDate <= schedulingHorizon
        else { return nil }
        return plannedDate
    }

    /// Delete by IndexSet
    func delete(_ uuids: Set<UUID>) {
        let definitionsToRemove = globaltimer.allSchedules.compactMap { schedule -> SchedulesConfigurations? in
            uuids.contains(schedule.id) ? schedule.scheduledata : nil
        }
        globaltimer.allSchedules.removeAll { schedule in
            uuids.contains(schedule.id)
        }
        scheduleDefinitions.removeAll { definition in
            definitionsToRemove.contains(where: { $0.id == definition.id })
        }
        globaltimer.refreshTimerAfterScheduleMutation()
    }

    /// Delete by IndexSet
    func deletenotexecuted(_ uuids: Set<UUID>) {
        globaltimer.notExecutedSchedulesafterWakeUp.removeAll { schedule in
            uuids.contains(schedule.id)
        }
        globaltimer.thereisnotexecutedschedulesafterwakeup = globaltimer.notExecutedSchedulesafterWakeUp.isEmpty == false
    }

    private var schedulingHorizon: Date {
        if lastdateinnextmonth == nil {
            lastdateinnextmonth = computelastdateinnextmonth()
        }
        return lastdateinnextmonth ?? Date.now.endOfCurrentMonth
    }

    private func uniquedScheduleDefinitions(_ schedules: [SchedulesConfigurations]) -> [SchedulesConfigurations] {
        var result = [SchedulesConfigurations]()
        for schedule in schedules where result.contains(where: { sameScheduleDefinition($0, schedule) }) == false {
            result.append(schedule)
        }
        return result
    }

    private func sameScheduleDefinition(_ lhs: SchedulesConfigurations, _ rhs: SchedulesConfigurations) -> Bool {
        lhs.profile == rhs.profile &&
            lhs.dateRun == rhs.dateRun &&
            lhs.schedule == rhs.schedule
    }
}
