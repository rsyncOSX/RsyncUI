import AppKit
import Foundation
import Observation
import OSLog

@Observable
@MainActor
final class GlobalTimer {
    static let shared = GlobalTimer()

    private init() {
        setupWakeNotification()
    }

    var timer: Timer?
    @ObservationIgnored var schedule: String?

    private var schedules: [String: (time: Date, callback: () -> Void)] = [:]
    private var backgroundschedules: [String: NSBackgroundActivityScheduler] = [:]
    private var wakeObserver: NSObjectProtocol?

    func addschedule(profile: String?, time: Date, callback: @escaping () -> Void) {
        let profileName = profile ?? "Default"
        Logger.process.info("GlobalTimer: addSchedule() - profile \(profileName) at time \(time)")

        schedules[profileName] = (time, callback)

        // Create background scheduler for this profile
        let scheduler = NSBackgroundActivityScheduler(identifier: "no.blogspot.RsyncUI.\(profileName)")

        // Calculate interval from now to scheduled time
        let interval = time.timeIntervalSince(Date.now)

        if interval > 0 {
            scheduler.interval = interval
            scheduler.repeats = false
            scheduler.qualityOfService = .userInitiated

            scheduler.schedule { completion in
                Task { @MainActor in
                    Logger.process.info("GlobalTimer: Background scheduler fired for \(profileName)")

                    let timerInstance = GlobalTimer.shared
                    if let schedule = timerInstance.schedules[profileName] {
                        if Date.now >= schedule.time {
                            schedule.callback()
                            timerInstance.schedules.removeValue(forKey: profileName)
                            timerInstance.backgroundschedules.removeValue(forKey: profileName)
                        }
                    }

                    completion(.finished)
                }
            }

            backgroundschedules[profileName] = scheduler
        }

        // Also start regular timer as backup for when app is active
        start()
    }

    func clearschedules() {
        guard schedules.count > 0 else {
            Logger.process.info("GlobalTimer: clearschedules() NO timer to invalidate")
            timer?.invalidate()
            timer = nil
            return
        }        
        // Invalidate all background schedulers
        for (_, scheduler) in backgroundschedules {
            
            Logger.process.info("GlobalTimer: clearschedules() and INVALIDATE backgroundschedules")
            scheduler.invalidate()
        }
        Logger.process.info("GlobalTimer: clearschedules() REMOVE all schedules and backgroundschedules")
        backgroundschedules.removeAll()
        schedules.removeAll()
        Logger.process.info("GlobalTimer: clearschedules() and INVALIDATE first timer")
        timer?.invalidate()
        timer = nil
    }

    private func start() {
        if timer == nil {
            Logger.process.info("GlobalTimer: start() new timer")

            timer = Timer.scheduledTimer(timeInterval: 60.0,
                                         target: self,
                                         selector: #selector(checkschedules),
                                         userInfo: nil,
                                         repeats: true)
        }
    }

    @objc private func checkschedules() {
        let now = Date.now
        var fired: [String] = []

        for (name, schedule) in schedules {
            Logger.process.info("GlobalTimer: checkschedules(): Date.now \(now) and schedule.time \(schedule.time)")

            if now >= schedule.time {
                Logger.process.info("GlobalTimer: checkschedules() - timer \(name) fired")
                schedule.callback()
                fired.append(name)
            }
        }

        // Clean up fired schedules
        for name in fired {
            Logger.process.info("GlobalTimer: checkschedules() - removed \(name)")
            schedules.removeValue(forKey: name)
            backgroundschedules[name]?.invalidate()
            backgroundschedules.removeValue(forKey: name)
        }

        // Stop timer if no more schedules
        if schedules.isEmpty {
            timer?.invalidate()
            timer = nil
            // And remove the Observer
            cleanup()
        }
    }

    // Check schedules when system wakes up
    private func setupWakeNotification() {
        wakeObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didWakeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor in
                Logger.process.info("GlobalTimer: System woke up, checking schedules")
                checkschedules()
            }
        }
    }

    // Call this when your app terminates if needed (optional cleanup)
    func cleanup() {
        if let observer = wakeObserver {
            Logger.process.info("GlobalTimer: cleanup - removing wake notification observer")
            NSWorkspace.shared.notificationCenter.removeObserver(observer)
            wakeObserver = nil
        }
    }
}
