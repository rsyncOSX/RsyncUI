//
//  GlobalTimer.swift
//  Calendar
//
//  Created by Thomas Evensen on 31/03/2025.
//

import Foundation
import Observation
import OSLog

@Observable
final class GlobalTimer {
    @MainActor static let shared = GlobalTimer()

    private init() {}

    private var timer: Timer?
    private var schedules: [String: (time: Date, callback: () -> Void)] = [:]

    func addSchedule(profile: String, time: Date, callback: @escaping () -> Void) {
        Logger.process.info("GlobalTimer: addSchedule() - profile \(profile) at time \(time)")

        schedules[profile] = (time, callback)
        start()
    }

    /*
     func removeSchedule(name: String) {
         schedules.removeValue(forKey: name)
         if schedules.isEmpty {
             timer?.invalidate()
             timer = nil
         }
     }
     */
    func clearSchedules() {
        guard schedules.count > 0 else {
            timer?.invalidate()
            timer = nil
            return
        }

        Logger.process.info("GlobalTimer: clearSchedules() and invalidate timer")

        schedules.removeAll()
        timer?.invalidate()
        timer = nil
    }

    private func start() {
        if timer == nil {
            Logger.process.info("GlobalTimer: start() new timer")

            timer = Timer.scheduledTimer(timeInterval: 60.0,
                                         target: self,
                                         selector: #selector(checkSchedules),
                                         userInfo: nil,
                                         repeats: true)
        }
    }

    @objc private func checkSchedules() {
        for (name, schedule) in schedules {
            Logger.process.info("GlobalTimer: checkSchedules() - Date.now \(Date.now)")
            Logger.process.info("GlobalTimer: checkSchedules() - schedule.time \(schedule.time)")

            if Date.now >= schedule.time {
                Logger.process.info("GlobalTimer: checkSchedules() - timer \(name) fired")

                schedule.callback()
            }
        }
    }
}
