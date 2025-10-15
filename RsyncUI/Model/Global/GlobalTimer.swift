import AppKit
import Foundation
import Observation
import OSLog

@Observable
@MainActor
final class GlobalTimer {

    static let shared = GlobalTimer()

    // MARK: - Types

    private struct ScheduledItem {
        let time: Date
        let callback: () -> Void
    }

    // MARK: - Properties (not observed)
    
    @ObservationIgnored
    var schedule: String?

    @ObservationIgnored
    var timer: Timer?

    @ObservationIgnored
    private var backgroundSchedulers: [String: NSBackgroundActivityScheduler] = [:]

    @ObservationIgnored
    private var wakeObserver: NSObjectProtocol?

    // Debounced wake-check task (canceled/replaced on subsequent wake events)
    @ObservationIgnored
    private var wakeCheckTask: Task<Void, Never>?

    // Schedules that should be observed
    private var schedules: [String: ScheduledItem] = [:]

    // MARK: - Initialization

    private init() {
        setupWakeNotification()
    }

    // MARK: - Public API

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

    func clearSchedules() {
        guard !schedules.isEmpty || !backgroundSchedulers.isEmpty else {
            Logger.process.info("GlobalTimer: No schedules to clear")
            stopTimerIfNoSchedules()
            return
        }

        Logger.process.info("GlobalTimer: Clearing all schedules and timers")

        for (profileName, scheduler) in backgroundSchedulers {
            scheduler.invalidate()
            Logger.process.info("GlobalTimer: Invalidated background scheduler for '\(profileName)'")
        }

        backgroundSchedulers.removeAll()
        schedules.removeAll()

        stopTimerIfNoSchedules()
        Logger.process.info("GlobalTimer: All schedules cleared")
    }

    /// Call on app termination if you want to explicitly drop observers and pending tasks.
    func cleanup() {
        if let observer = wakeObserver {
            Logger.process.info("GlobalTimer: Removing wake notification observer")
            NSWorkspace.shared.notificationCenter.removeObserver(observer)
            wakeObserver = nil
        }
        wakeCheckTask?.cancel()
        wakeCheckTask = nil
        timer?.invalidate()
        timer = nil
    }

    // MARK: - Private

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

        for profileName in dueProfiles {
            schedules.removeValue(forKey: profileName)
            if let scheduler = backgroundSchedulers.removeValue(forKey: profileName) {
                scheduler.invalidate()
            }
            Logger.process.info("GlobalTimer: Removed executed schedule for '\(profileName, privacy: .public)'")
        }

        stopTimerIfNoSchedules()
    }

    private func executeScheduleIfCurrent(profileName: String, scheduledTime: Date) {
        guard let item = schedules[profileName] else {
            Logger.process.info("GlobalTimer: No schedule found for '\(profileName)'")
            return
        }

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

    // MARK: - Wake handling (debounced, cancelable)

    private func setupWakeNotification() {
        guard wakeObserver == nil else { return }
        wakeObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didWakeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            // Hop to the MainActor before calling a @MainActor method
            Task { @MainActor in
                self?.scheduleWakeCheck()
            }
        }
    }

    private func scheduleWakeCheck(delaySeconds: UInt64 = 3) {
        // Cancel any in-flight check and schedule a new one
        wakeCheckTask?.cancel()
        Logger.process.info("GlobalTimer: System woke up, scheduling debounced check in ~\(delaySeconds, privacy: .public) seconds...")
        wakeCheckTask = Task { [weak self] in
            // Sleep first; only strengthen self after the suspension point.
            try? await Task.sleep(nanoseconds: delaySeconds * 1_000_000_000)
            await MainActor.run {
                guard let self else { return }
                Logger.process.info("GlobalTimer: Running debounced wake check")
                self.checkSchedules()
            }
        }
    }
}
