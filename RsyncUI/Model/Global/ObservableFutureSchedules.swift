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
    
    @ObservationIgnored var lastdateinpresentmont: Date?
    @ObservationIgnored var scheduledata: [SchedulesConfigurations]?
    @ObservationIgnored var demo: Bool = false
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
            let count = scheduledata?.count ?? 0
            Logger.process.info("ObservableFutureSchedules: private computefuturedates(): (\(count))")
        }
    }

    private func appendfutureschedule(profile: String?, dateRun: String, schedule: String) {
        guard dateRun.en_date_from_string() >= Date.now else { return }
        let futureschedule = SchedulesConfigurations(profile: profile,
                                                     dateAdded: nil,
                                                     dateRun: dateRun,
                                                     schedule: schedule)
        addtaskandcallback(futureschedule)
    }

    // Recompute the calendardata to only show active schedules in row.
    func recomputeschedules() {
        
        Logger.process.info("ObservableFutureSchedules: recomputeschedules()")
        
        let recomputedschedules = scheduledata?.filter { item in
            if let dateRunString = item.dateRun {
                return dateRunString.en_date_from_string() > Date.now
            }
            return false
        } ?? []

        guard recomputedschedules.count > 0 else {
            scheduledata?.removeAll()
            GlobalTimer.shared.invaldiateallschedulesandtimer()
            Logger.process.info("ObservableFutureSchedules: recomputeschedules() no schdeules")
            return
        }
        
        Logger.process.info("ObservableFutureSchedules: recomputeschedules() number of schedules: \(recomputedschedules.count, privacy: .public)")
        
        for i in 0 ..< recomputedschedules.count {
            if let schedule = recomputedschedules[i].schedule,
               let dateRun = recomputedschedules[i].dateRun?.validate_en_date_from_string() {
                computefuturedates(profile: recomputedschedules[i].profile, schedule: schedule, dateRun: dateRun)
            }
        }
    }

    // Only set when loading data, when new schedules added or deleted
    func setfirsscheduledate() {
        
        let dates = scheduledata?.sorted { s1, s2 in
            if let id1 = s1.dateRun?.en_date_from_string(), let id2 = s2.dateRun?.en_date_from_string() {
                return id1 < id2
            }
            return false
        }
        if dates?.count ?? 0 > 0 {
            let first = SchedulesConfigurations(profile: dates?.first?.profile,
                                                dateAdded: nil,
                                                dateRun: dates?.first?.dateRun,
                                                schedule: "")

            firstscheduledate = first
            addtaskandcallback(first)

        } else {
            
            firstscheduledate = nil
        }
    }
    
    func recalculateschedulesGlobalTimer() {
        let globalTimer = GlobalTimer.shared
        
        for i in 0 ..< (scheduledata?.count ?? 0) {
            if let schedultime = scheduledata?[i].dateRun?.en_date_from_string() {
                let callback: () -> Void = {
                    self.recomputeschedules()
                    self.setfirsscheduledate()
                    // Setting profile name will trigger execution
                    self.scheduledprofile = self.scheduledata?[i].profile ?? "Default"
                    Task {
                        // Logging to file that a Schedule is fired
                        await ActorLogToFile(command: "Schedule", stringoutputfromrsync: ["ObservableFutureSchedules: schedule FIRED for \(self.scheduledata?[i].profile ?? "Default")"])
                    }
                }
                
                globalTimer.addSchedule(time: schedultime, tolerance: 10, callback: callback)
            }
        }
    }

    private func addtaskandcallback(_ schedule: SchedulesConfigurations) {
        let globalTimer = GlobalTimer.shared
        
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
            globalTimer.addSchedule(time: schedultime, tolerance: 10, callback: callback)
        }
    }

    // Demo for test av schedule

    func demodatatestschedule() {
        // Must set demo = true to stop trigger for SidebarMainView
        demo = true
        let schedule1 = SchedulesConfigurations(profile: nil, dateAdded: Date.now.en_string_from_date(), dateRun: Date.now.addingTimeInterval(60).en_string_from_date(), schedule: ScheduleType.once.rawValue)
        let schedule2 = SchedulesConfigurations(profile: nil, dateAdded: Date.now.en_string_from_date(), dateRun: Date.now.addingTimeInterval(60 * 2).en_string_from_date(), schedule: ScheduleType.once.rawValue)
        let schedule3 = SchedulesConfigurations(profile: nil, dateAdded: Date.now.en_string_from_date(), dateRun: Date.now.addingTimeInterval(60 * 3).en_string_from_date(), schedule: ScheduleType.once.rawValue)
        let schedule12 = SchedulesConfigurations(profile: nil, dateAdded: Date.now.en_string_from_date(), dateRun: Date.now.addingTimeInterval(60 * 4).en_string_from_date(), schedule: ScheduleType.once.rawValue)
        let schedule22 = SchedulesConfigurations(profile: nil, dateAdded: Date.now.en_string_from_date(), dateRun: Date.now.addingTimeInterval(60 * 5).en_string_from_date(), schedule: ScheduleType.once.rawValue)
        let schedule32 = SchedulesConfigurations(profile: nil, dateAdded: Date.now.en_string_from_date(), dateRun: Date.now.addingTimeInterval(60 * 6).en_string_from_date(), schedule: ScheduleType.once.rawValue)

        scheduledata = [schedule1, schedule2, schedule3, schedule12, schedule22, schedule32]

        if let scheduledata {
            for i in 0 ..< scheduledata.count {
                if let schedule = scheduledata[i].schedule,
                   let dateRun = scheduledata[i].dateRun?.validate_en_date_from_string()
                {
                    computefuturedates(profile: scheduledata[i].profile, schedule: schedule, dateRun: dateRun)
                }
            }
        }

        addschedulesdemo()
        setfirsscheduledatedemo()
    }
    
    func setfirsscheduledatedemo() {
        let dates = scheduledata?.sorted { s1, s2 in
            if let id1 = s1.dateRun?.en_date_from_string(), let id2 = s2.dateRun?.en_date_from_string() {
                return id1 < id2
            }
            return false
        }
        if dates?.count ?? 0 > 0 {
            let first = SchedulesConfigurations(profile: dates?.first?.profile,
                                                dateAdded: nil,
                                                dateRun: dates?.first?.dateRun,
                                                schedule: "")

            firstscheduledate = first

        } else {
            firstscheduledate = nil
            GlobalTimer.shared.invaldiateallschedulesandtimer()
        }
    }
    
    
    private func addschedulesdemo() {
        let globalTimer = GlobalTimer.shared
       
        let callback: () -> Void = {
            self.recomputeschedules()
            self.setfirsscheduledatedemo()
            Task {
                // Logging to file that a Schedule is fired
                await ActorLogToFile(command: "Schedule", stringoutputfromrsync: ["ObservableFutureSchedules: schedule FIRED for DEMO"])
            }
        }
        
        for i in 0 ..< (scheduledata?.count ?? 0) {
            if let schedultime = scheduledata?[i].dateRun?.en_date_from_string() {
                globalTimer.addSchedule(time: schedultime, tolerance: 10, callback: callback)
            }
        }
    }
}
