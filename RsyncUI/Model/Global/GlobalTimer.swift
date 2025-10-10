//
//  GlobalTimer.swift
//  Calendar
//
//  Created by Thomas Evensen on 31/03/2025.
//

import Foundation
import Observation
import OSLog
import AppKit

@Observable
final class GlobalTimer {
    
    @MainActor static let shared = GlobalTimer()

    private init() {
        setupWakeNotification()
    }

    var timer: Timer?
    @ObservationIgnored var schedule: String?

    private var schedules: [String: (time: Date, callback: () -> Void)] = [:]
    private var schedulers: [String: NSBackgroundActivityScheduler] = [:]

    func addSchedule(profile: String?, time: Date, callback: @escaping () -> Void) {
        let profileName = profile ?? "Default"
        Logger.process.info("GlobalTimer: addSchedule() - profile \(profileName) at time \(time)")
        
        schedules[profileName] = (time, callback)
        
        // Create background scheduler for this profile
        let scheduler = NSBackgroundActivityScheduler(identifier: "com.yourapp.scheduler.\(profileName)")
        
        // Calculate interval from now to scheduled time
        let interval = time.timeIntervalSince(Date.now)
        
        if interval > 0 {
            scheduler.interval = interval
            scheduler.repeats = false
            scheduler.qualityOfService = .userInitiated
            
            scheduler.schedule { [weak self] completion in
                guard let self = self else {
                    completion(.finished)
                    return
                }
                
                Task { @MainActor in
                    Logger.process.info("GlobalTimer: Background scheduler fired for \(profileName)")
                    
                    if let schedule = self.schedules[profileName] {
                        if Date.now >= schedule.time {
                            schedule.callback()
                            self.schedules.removeValue(forKey: profileName)
                            self.schedulers.removeValue(forKey: profileName)
                        }
                    }
                    
                    completion(.finished)
                }
            }
            
            schedulers[profileName] = scheduler
        }
        
        // Also start regular timer as backup for when app is active
        start()
    }

    func clearSchedules() {
        guard schedules.count > 0 else {
            Logger.process.info("GlobalTimer: clearSchedules() NO timer to invalidate")
            timer?.invalidate()
            timer = nil
            return
        }

        Logger.process.info("GlobalTimer: clearSchedules() and INVALIDATE old timer")

        // Invalidate all background schedulers
        for (_, scheduler) in schedulers {
            scheduler.invalidate()
        }
        schedulers.removeAll()
        
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
        let now = Date.now
        var fired: [String] = []
        
        for (name, schedule) in schedules {
            Logger.process.info("GlobalTimer: checkSchedules(): Date.now \(now) and schedule.time \(schedule.time)")

            if now >= schedule.time {
                Logger.process.info("GlobalTimer: checkSchedules() - timer \(name) fired")
                schedule.callback()
                fired.append(name)
            }
        }
        
        // Clean up fired schedules
        for name in fired {
            schedules.removeValue(forKey: name)
            schedulers[name]?.invalidate()
            schedulers.removeValue(forKey: name)
        }
        
        // Stop timer if no more schedules
        if schedules.isEmpty {
            timer?.invalidate()
            timer = nil
        }
    }
    
    // Check schedules when system wakes up
    private func setupWakeNotification() {
        NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didWakeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Logger.process.info("GlobalTimer: System woke up, checking schedules")
            self?.checkSchedules()
        }
    }
    
    deinit {
        NSWorkspace.shared.notificationCenter.removeObserver(self)
    }
}
