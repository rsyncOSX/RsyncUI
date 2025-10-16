//
//  ObservableFutureSchedules.swift
//  Calendar
//
//  Created by Thomas Evensen on 27/03/2025.
//

import Foundation
import Observation
import OSLog
import SwiftUI

@Observable @MainActor
final class ObservableFutureSchedules {
    @ObservationIgnored var futureschedules = Set<SchedulesConfigurations>()
    @ObservationIgnored var lastdateinpresentmont: Date?
    @ObservationIgnored var scheduledata: [SchedulesConfigurations]?
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

    private func appendfutureschedule(profile: String?, dateRun: String, schedule: String) {
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
                if let schedule = scheduledata[i].schedule,
                   let dateRun = scheduledata[i].dateRun?.validate_en_date_from_string()
                {
                    computefuturedates(profile: scheduledata[i].profile, schedule: schedule, dateRun: dateRun)
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
            starttimer(first)
            
        } else {
            firstscheduledate = nil
            GlobalTimer.shared.clearSchedules()
        }
    }

    private func starttimer(_ schedule: SchedulesConfigurations) {
        let globalTimer = GlobalTimer.shared
        // Remove and cancel any schedules
        globalTimer.clearSchedules()
        
        // The Callback for Schedule
        let callback: () -> Void = {
            self.recomputeschedules()
            self.setfirsscheduledate()
            // Setting profile name will trigger execution
            self.scheduledprofile = schedule.profile ?? "Default"
            Task {
                // Logging to file that a Schedule is fired
                await ActorLogToFile(command: "Schedule", stringoutputfromrsync: ["ObservableFutureSchedules: schedule FIRED for \(schedule.profile ?? "Default")"])
            }
        }
        // Then add new schedule
        if let schedultime = schedule.dateRun?.en_date_from_string() {
            globalTimer.addSchedule(profile: schedule.profile, time: schedultime, tolerance: 10, callback: callback)
        }
    }
    
    // Test for the awake function
    
    
    func testawake() {
        
        let globalTimer = GlobalTimer.shared
        // Remove and cancel any schedules
        globalTimer.clearSchedules()
        
        let profile1 = "profile1"
        let profile2 = "profile2"
        let profile3 = "profile3"
        
        let schedule1 = SchedulesConfigurations(profile: profile1, dateAdded: Date.now.en_string_from_date(), dateRun: Date.now.addingTimeInterval(-60 * 2).en_string_from_date(), schedule: ScheduleType.once.rawValue)
        let schedule2 = SchedulesConfigurations(profile: profile2, dateAdded: Date.now.en_string_from_date(), dateRun: Date.now.addingTimeInterval(-60 * 3).en_string_from_date(), schedule: ScheduleType.once.rawValue)
        let schedule3 = SchedulesConfigurations(profile: profile3, dateAdded: Date.now.en_string_from_date(), dateRun: Date.now.addingTimeInterval(-60 * 4).en_string_from_date(), schedule: ScheduleType.once.rawValue)
        let schedule12 = SchedulesConfigurations(profile: profile1, dateAdded: Date.now.en_string_from_date(), dateRun: Date.now.addingTimeInterval(-60 * 5).en_string_from_date(), schedule: ScheduleType.once.rawValue)
        let schedule22 = SchedulesConfigurations(profile: profile2, dateAdded: Date.now.en_string_from_date(), dateRun: Date.now.addingTimeInterval(-60 * 6).en_string_from_date(), schedule: ScheduleType.once.rawValue)
        let schedule32 = SchedulesConfigurations(profile: profile3, dateAdded: Date.now.en_string_from_date(), dateRun: Date.now.addingTimeInterval(-60 * 7).en_string_from_date(), schedule: ScheduleType.once.rawValue)
        
        let callback1: () -> Void = {
            self.recomputeschedules()
            self.setfirsscheduledate()
            Task {
                // Logging to file that a Schedule is fired
                await ActorLogToFile(command: "Schedule", stringoutputfromrsync: ["ObservableFutureSchedules: schedule FIRED for profile1"])
            }
        }
        
        let callback2: () -> Void = {
            self.recomputeschedules()
            self.setfirsscheduledate()
            Task {
                // Logging to file that a Schedule is fired
                await ActorLogToFile(command: "Schedule", stringoutputfromrsync: ["ObservableFutureSchedules: schedule FIRED for profile2"])
            }
        }
        
        let callback3: () -> Void = {
            self.recomputeschedules()
            self.setfirsscheduledate()
            Task {
                // Logging to file that a Schedule is fired
                await ActorLogToFile(command: "Schedule", stringoutputfromrsync: ["ObservableFutureSchedules: schedule FIRED for profile3"])
            }
        }
        
        scheduledata = [schedule1, schedule2, schedule3, schedule12, schedule22, schedule32]
        
        recomputeschedules()
        
        if let schedultime = schedule1.dateRun?.en_date_from_string() {
            globalTimer.addSchedule(profile: schedule1.profile, time: schedultime, tolerance: 10, callback: callback1)
        }
        
        if let schedultime = schedule2.dateRun?.en_date_from_string() {
            globalTimer.addSchedule(profile: schedule2.profile, time: schedultime, tolerance: 10, callback: callback2)
        }
        
        if let schedultime = schedule3.dateRun?.en_date_from_string() {
            globalTimer.addSchedule(profile: schedule3.profile, time: schedultime, tolerance: 10, callback: callback3)
        }
        
        if let schedultime = schedule12.dateRun?.en_date_from_string() {
            globalTimer.addSchedule(profile: schedule12.profile, time: schedultime, tolerance: 10, callback: callback1)
        }
        
        if let schedultime = schedule22.dateRun?.en_date_from_string() {
            globalTimer.addSchedule(profile: schedule22.profile, time: schedultime, tolerance: 10, callback: callback2)
        }
        
        if let schedultime = schedule32.dateRun?.en_date_from_string() {
            globalTimer.addSchedule(profile: schedule32.profile, time: schedultime, tolerance: 10, callback: callback3)
        }
        
        globalTimer.startdemo()
    }
}

