//
//  ObservableSchedulesTests.swift
//  RsyncUITests
//

import Foundation
@testable import RsyncUI
import Testing

@MainActor
@Suite(.serialized, .tags(.schedules))
struct ObservableSchedulesTests {
    @Test("Deleting earliest schedule reschedules to next earliest")
    func deletingEarliestScheduleReschedulesTimer() throws {
        let schedules = makeCleanSchedules()
        let first = try #require(Calendar.current.date(byAdding: .minute, value: 30, to: Date.now))
        let second = try #require(Calendar.current.date(byAdding: .minute, value: 45, to: Date.now))

        #expect(schedules.appendSchedule(profile: nil, dateRun: first.en_string_from_date(), schedule: ScheduleType.once.rawValue))
        #expect(schedules.appendSchedule(profile: "Work", dateRun: second.en_string_from_date(), schedule: ScheduleType.once.rawValue))

        let firstID = try #require(GlobalTimer.shared.allSchedules.first?.id)
        schedules.delete([firstID])

        #expect(GlobalTimer.shared.allSchedules.count == 1)
        #expect(GlobalTimer.shared.timerIsActive())
        #expect(GlobalTimer.shared.firstscheduledate?.profile == "Work")
        #expect(GlobalTimer.shared.firstscheduledate?.dateRun == second.en_string_from_date())
    }

    @Test("Deleting only schedule clears first schedule and timer")
    func deletingOnlyScheduleClearsTimer() throws {
        let schedules = makeCleanSchedules()
        let runDate = try #require(Calendar.current.date(byAdding: .minute, value: 30, to: Date.now))

        #expect(schedules.appendSchedule(profile: nil, dateRun: runDate.en_string_from_date(), schedule: ScheduleType.once.rawValue))

        let onlyID = try #require(GlobalTimer.shared.allSchedules.first?.id)
        schedules.delete([onlyID])

        #expect(GlobalTimer.shared.allSchedules.isEmpty)
        #expect(GlobalTimer.shared.firstscheduledate == nil)
        #expect(GlobalTimer.shared.timerIsActive() == false)
    }

    @Test("Daily and weekly schedule definitions do not duplicate when recomputed or reloaded")
    func repeatingSchedulesDoNotDuplicate() throws {
        let schedules = makeCleanSchedules()
        let daily = try #require(Calendar.current.date(byAdding: .day, value: 1, to: Date.now))
        let weekly = try #require(Calendar.current.date(byAdding: .day, value: 7, to: Date.now))

        #expect(schedules.appendSchedule(profile: nil, dateRun: daily.en_string_from_date(), schedule: ScheduleType.daily.rawValue))
        #expect(schedules.appendSchedule(profile: "Work",
                                         dateRun: weekly.en_string_from_date(),
                                         schedule: ScheduleType.weekly.rawValue))

        let firstExpansionCount = GlobalTimer.shared.allSchedules.count
        let persistedDefinitions = schedules.scheduleDataForPersistence()

        schedules.recomputeschedules()
        #expect(GlobalTimer.shared.allSchedules.count == firstExpansionCount)
        #expect(schedules.scheduleDataForPersistence().count == 2)

        let reloadedSchedules = makeCleanSchedules()
        reloadedSchedules.appendschdeuldatafromfile(persistedDefinitions)

        #expect(GlobalTimer.shared.allSchedules.count == firstExpansionCount)
        #expect(reloadedSchedules.scheduleDataForPersistence().count == 2)
    }

    @Test("Date horizon uses full dates across December and January")
    func scheduleHorizonCrossesYearBoundary() throws {
        let schedules = makeCleanSchedules()
        let decemberRun = try #require(Calendar.current.date(from: DateComponents(year: 2026, month: 12, day: 31, hour: 8, minute: 0)))
        let januaryHorizon = try #require(
            Calendar.current.date(from: DateComponents(year: 2027, month: 1, day: 31, hour: 23, minute: 59))
        )

        schedules.lastdateinnextmonth = januaryHorizon
        schedules.appendschdeuldatafromfile([
            SchedulesConfigurations(profile: nil,
                                    dateAdded: Date.now.en_string_from_date(),
                                    dateRun: decemberRun.en_string_from_date(),
                                    schedule: ScheduleType.daily.rawValue)
        ])

        #expect(GlobalTimer.shared.allSchedules.contains { item in
            item.scheduledata?.dateRun == "01 Jan 2027 08:00"
        })
    }

    @Test("Invalid and beyond-horizon schedule strings are rejected")
    func invalidAndBeyondHorizonSchedulesAreRejected() throws {
        let schedules = makeCleanSchedules()
        let beyondHorizon = try #require(
            Calendar.current.date(byAdding: .day, value: 1, to: schedules.computelastdateinnextmonth() ?? Date.now)
        )

        #expect(schedules.validPlannedScheduleDate("not a date") == nil)
        #expect(schedules.verifynextschedule(plannednextschedule: "not a date") == false)
        #expect(schedules.validPlannedScheduleDate(beyondHorizon.en_string_from_date()) == nil)
        #expect(schedules.appendSchedule(profile: nil,
                                         dateRun: beyondHorizon.en_string_from_date(),
                                         schedule: ScheduleType.once.rawValue) == false)
    }

    @Test("Validation follows edited planned run value")
    func validationUsesPlannedRunValue() throws {
        let schedules = makeCleanSchedules()
        let validRun = try #require(Calendar.current.date(byAdding: .minute, value: 30, to: Date.now))
        let invalidRun = try #require(Calendar.current.date(byAdding: .minute, value: -30, to: Date.now))

        #expect(schedules.validPlannedScheduleDate(validRun.en_string_from_date()) != nil)
        #expect(schedules.verifynextschedule(plannednextschedule: validRun.en_string_from_date()))
        #expect(schedules.validPlannedScheduleDate(invalidRun.en_string_from_date()) == nil)
        #expect(schedules.appendSchedule(profile: nil, dateRun: validRun.en_string_from_date(), schedule: ScheduleType.once.rawValue))
    }

    private func makeCleanSchedules() -> ObservableSchedules {
        GlobalTimer.shared.invalidateAllSchedulesAndTimer()
        GlobalTimer.shared.firstscheduledate = nil
        GlobalTimer.shared.scheduledprofile = ""
        GlobalTimer.shared.notExecutedSchedulesafterWakeUp.removeAll()
        GlobalTimer.shared.thereisnotexecutedschedulesafterwakeup = false
        let schedules = ObservableSchedules()
        schedules.lastdateinnextmonth = schedules.computelastdateinnextmonth()
        return schedules
    }
}
