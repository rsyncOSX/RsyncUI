import AppKit
import Foundation
import Observation
import OSLog

@Observable
@MainActor
final class GlobalTimer {

    static let shared = GlobalTimer()
    
    /// Currently active schedule identifier
    @ObservationIgnored var schedule: String?

    // MARK: - Types

    private struct ScheduledItem {
        let time: Date
        let callback: () -> Void
    }

    // MARK: - Properties

    /// Foreground backup timer that checks schedules every 60 seconds.
    var timer: Timer?

    /// All scheduled tasks keyed by profile name.
    private var schedules: [String: ScheduledItem] = [:]

    /// One background scheduler per profile.
    private var backgroundSchedulers: [String: NSBackgroundActivityScheduler] = [:]

    /// Observer for system wake notifications.
    private var wakeObserver: NSObjectProtocol?

    // MARK: - Initialization

    private init() {
        setupWakeNotification()
    }

    // MARK: - Public API

    /// Schedule a task for a profile to run at an exact time (best-effort).
    /// - Parameters:
    ///   - profile: Profile identifier (defaults to "Default").
    ///   - time: Target execution time.
    ///   - callback: Closure executed when due.
    func addSchedule(profile: String?, time: Date, callback: @escaping () -> Void) {
        let profileName = profile ?? "Default"
        Logger.process.info("GlobalTimer: Adding schedule for profile '\(profileName)' at \(time, privacy: .public)")

        // Cancel and remove any existing background scheduler for this profile.
        if let existing = backgroundSchedulers[profileName] {
            existing.invalidate()
            backgroundSchedulers.removeValue(forKey: profileName)
            Logger.process.info("GlobalTimer: Cancelled existing scheduler for '\(profileName)'")
        }

        // Store or replace the schedule.
        schedules[profileName] = ScheduledItem(time: time, callback: callback)

        // Configure background scheduler for best-effort execution around 'time'.
        let interval = time.timeIntervalSince(Date())
        if interval > 1 {
            let scheduler = NSBackgroundActivityScheduler(identifier: "no.blogspot.RsyncUI.\(profileName)")
            scheduler.repeats = false
            scheduler.interval = interval
            scheduler.tolerance = min(60, max(5, interval / 10)) // reasonable flexibility
            scheduler.qualityOfService = .utility

            scheduler.schedule { [weak self] completion in
                guard let self else {
                    completion(.finished)
                    return
                }
                Task { @MainActor in
                    Logger.process.info("GlobalTimer: Background scheduler fired for '\(profileName)'")
                    self.executeScheduleIfCurrent(profileName: profileName, scheduledTime: time)
                    // Ensure this scheduler won't fire again.
                    self.backgroundSchedulers[profileName]?.invalidate()
                    self.backgroundSchedulers.removeValue(forKey: profileName)
                    completion(.finished)
                }
            }

            backgroundSchedulers[profileName] = scheduler
            Logger.process.info("GlobalTimer: Background scheduler configured for '\(profileName)'")
        } else {
            Logger.process.warning("GlobalTimer: Scheduled time for '\(profileName)' is in the past or too soon, skipping background scheduler")
        }

        // Start/ensure the foreground backup timer.
        startForegroundTimer()
    }

    /// Remove an existing schedule for a given profile, if any.
    func removeSchedule(profile: String) {
        if let scheduler = backgroundSchedulers.removeValue(forKey: profile) {
            scheduler.invalidate()
            Logger.process.info("GlobalTimer: Removed background scheduler for '\(profile)'")
        }
        if schedules.removeValue(forKey: profile) != nil {
            Logger.process.info("GlobalTimer: Removed schedule for '\(profile)'")
        }
        stopTimerIfNoSchedules()
    }

    /// Clears all scheduled tasks and invalidates all timers.
    func clearSchedules() {
        guard !schedules.isEmpty || !backgroundSchedulers.isEmpty else {
            Logger.process.info("GlobalTimer: No schedules to clear")
            stopTimerIfNoSchedules()
            return
        }

        // Invalidate all background schedulers
        for (profileName, scheduler) in backgroundSchedulers {
            scheduler.invalidate()
            Logger.process.info("GlobalTimer: Invalidated background scheduler for '\(profileName)'")
        }

        backgroundSchedulers.removeAll()
        schedules.removeAll()

        stopTimerIfNoSchedules()
        Logger.process.info("GlobalTimer: All schedules cleared")
    }

    /// Optional: Call on app termination if you want to explicitly drop observers.
    func cleanup() {
        if let observer = wakeObserver {
            Logger.process.info("GlobalTimer: Removing wake notification observer")
            NSWorkspace.shared.notificationCenter.removeObserver(observer)
            wakeObserver = nil
        }
        timer?.invalidate()
        timer = nil
    }

    // MARK: - Private

    /// Starts a foreground timer (if not already running) to check schedules every 60s.
    private func startForegroundTimer() {
        guard timer == nil else { return }

        Logger.process.info("GlobalTimer: Starting foreground timer")
        let t = Timer(timeInterval: 60.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.checkSchedules()
            }
        }
        // Use common modes so the timer isn't paused during UI tracking.
        RunLoop.main.add(t, forMode: .common)
        timer = t

        // Run an immediate check so short intervals still get picked up quickly.
        checkSchedules()
    }

    private func stopTimerIfNoSchedules() {
        if schedules.isEmpty {
            Logger.process.info("GlobalTimer: No more schedules, stopping timer")
            timer?.invalidate()
            timer = nil
        }
    }

    /// Checks all schedules and executes any that are due.
    @objc private func checkSchedules() {
        let now = Date()
        var dueProfiles: [String] = []

        for (profileName, item) in schedules {
            Logger.process.info("GlobalTimer: Checking '\(profileName)' - now: \(now, privacy: .public), scheduled: \(item.time, privacy: .public)")
            if now >= item.time {
                Logger.process.info("GlobalTimer: Executing schedule for '\(profileName)'")
                item.callback()
                dueProfiles.append(profileName)
            }
        }

        // Cleanup executed schedules
        for profileName in dueProfiles {
            schedules.removeValue(forKey: profileName)
            if let scheduler = backgroundSchedulers.removeValue(forKey: profileName) {
                scheduler.invalidate()
            }
            Logger.process.info("GlobalTimer: Removed executed schedule for '\(profileName)'")
        }

        stopTimerIfNoSchedules()
    }

    /// Executes a schedule if it's still current (not replaced by a newer schedule).
    private func executeScheduleIfCurrent(profileName: String, scheduledTime: Date) {
        guard let item = schedules[profileName] else {
            Logger.process.info("GlobalTimer: No schedule found for '\(profileName)'")
            return
        }

        // Only execute if this is still the current scheduled time.
        guard item.time == scheduledTime, Date() >= item.time else {
            Logger.process.info("GlobalTimer: Skipping stale or not-yet-due schedule for '\(profileName, privacy: .public)'")
            return
        }

        Logger.process.info("GlobalTimer: Executing callback for '\(profileName, privacy: .public)'")
        item.callback()

        schedules.removeValue(forKey: profileName)
        if let scheduler = backgroundSchedulers.removeValue(forKey: profileName) {
            scheduler.invalidate()
        }
    }

    /// Sets up notification observer for system wake events.
    private func setupWakeNotification() {
        guard wakeObserver == nil else { return }
        wakeObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didWakeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                Logger.process.info("GlobalTimer: System woke up, checking for missed schedules in ~3 seconds...")
                try? await Task.sleep(seconds: 3)
                guard let self = self else { return }
                Logger.process.info("GlobalTimer: System woke up, checking for missed schedules after sleep...")
                self.checkSchedules()
            }
        }
    }
}
