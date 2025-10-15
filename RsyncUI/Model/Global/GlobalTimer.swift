import AppKit
import Foundation
import Observation
import OSLog

@Observable
@MainActor
public final class GlobalTimer {

    public static let shared = GlobalTimer()

    // MARK: - Types

    private struct ScheduledItem {
        let time: Date
        let tolerance: TimeInterval?
        let callback: () -> Void
    }

    // MARK: - Properties
    
    /// Foreground one-shot timer (backup/precision timer). Exposed read-only, but not observed.
    @ObservationIgnored
    private var timer: Timer?

    /// One background scheduler per profile.
    @ObservationIgnored
    private var backgroundSchedulers: [String: NSBackgroundActivityScheduler] = [:]

    /// Observer token for system wake notifications.
    @ObservationIgnored
    private var wakeObserver: NSObjectProtocol?

    /// Debounced wake-check task (canceled/replaced on subsequent wake events).
    @ObservationIgnored
    private var wakeCheckTask: Task<Void, Never>?

    /// All scheduled tasks keyed by profile name.
    private var schedules: [String: ScheduledItem] = [:]

    // MARK: - Initialization

    private init() {
        setupWakeNotification()
    }

    // MARK: - Public API
    
    public func timerIsActive() -> Bool {
            timer != nil
        }

    /// Returns the date of the next scheduled task as a formatted string, or nil if no schedules exist.
        /// - Parameter format: Date format style (defaults to "medium" style).
        /// - Returns: Formatted date string of the earliest schedule, or nil if none.
        public func nextScheduleDate(format: Date.FormatStyle = .dateTime) -> String? {
            guard let nextItem = schedules.values.min(by: { $0.time < $1.time }) else {
                return nil
            }
            return nextItem.time.formatted(format)
        }
    
    /// Schedule a task for a profile to run at an exact time (best-effort).
    /// - Parameters:
    ///   - profile: Profile identifier (defaults to "Default").
    ///   - time: Target execution time.
    ///   - tolerance: Optional tolerance (seconds). If nil, a reasonable default is used.
    ///                Pass 0 for best precision. Used for both background activity and the foreground timer
    ///                when this item is the next due schedule.
    ///   - callback: Closure executed when due.
    public func addSchedule(profile: String?, time: Date, tolerance: TimeInterval? = nil, callback: @escaping () -> Void) {
        let profileName = profile ?? "Default"
        Logger.process.info("GlobalTimer: Adding schedule for profile '\(profileName, privacy: .public)' at \(time, privacy: .public) with tolerance \(tolerance ?? -1, privacy: .public)s")

        // Cancel and remove any existing background scheduler for this profile.
        if let existing = backgroundSchedulers.removeValue(forKey: profileName) {
            existing.invalidate()
            Logger.process.info("GlobalTimer: Cancelled existing scheduler for '\(profileName, privacy: .public)'")
        }

        // Store or replace the schedule (with per-schedule tolerance).
        schedules[profileName] = ScheduledItem(time: time, tolerance: normalizedTolerance(tolerance), callback: callback)

        // Configure background scheduler for best-effort execution around 'time'.
        let interval = time.timeIntervalSince(Date.now)
        if interval > 1 {
            let scheduler = NSBackgroundActivityScheduler(identifier: "no.blogspot.RsyncUI.\(profileName)")
            scheduler.repeats = false
            scheduler.interval = interval
            scheduler.tolerance = resolveBackgroundTolerance(requested: tolerance, interval: interval)
            scheduler.qualityOfService = .utility

            scheduler.schedule { [weak self] completion in
                guard let self else {
                    completion(.finished)
                    return
                }
                Task { @MainActor in
                    Logger.process.info("GlobalTimer: Background scheduler fired for '\(profileName, privacy: .public)'")
                    self.executeScheduleIfCurrent(profileName: profileName, scheduledTime: time)
                    // Ensure this scheduler won't fire again and re-evaluate next timer.
                    self.backgroundSchedulers[profileName]?.invalidate()
                    self.backgroundSchedulers.removeValue(forKey: profileName)
                    self.scheduleNextForegroundTimer()
                    completion(.finished)
                }
            }

            backgroundSchedulers[profileName] = scheduler
            Logger.process.info("GlobalTimer: Background scheduler configured for '\(profileName, privacy: .public)' with tolerance \(scheduler.tolerance, privacy: .public)s")
        } else {
            Logger.process.warning("GlobalTimer: Scheduled time for '\(profileName, privacy: .public)' is in the past or too soon, skipping background scheduler")
        }

        // Schedule/refresh the foreground one-shot timer.
        scheduleNextForegroundTimer()
    }

    /// Remove an existing schedule for a given profile, if any.
    public func removeSchedule(profile: String) {
        if let scheduler = backgroundSchedulers.removeValue(forKey: profile) {
            scheduler.invalidate()
            Logger.process.info("GlobalTimer: Removed background scheduler for '\(profile, privacy: .public)'")
        }
        if schedules.removeValue(forKey: profile) != nil {
            Logger.process.info("GlobalTimer: Removed schedule for '\(profile, privacy: .public)'")
        }
        scheduleNextForegroundTimer()
    }

    /// Clears all scheduled tasks and invalidates all timers.
    public func clearSchedules() {
        guard !schedules.isEmpty || !backgroundSchedulers.isEmpty else {
            Logger.process.info("GlobalTimer: No schedules to clear")
            scheduleNextForegroundTimer()
            return
        }

        Logger.process.info("GlobalTimer: Clearing all schedules and timers")

        for (profileName, scheduler) in backgroundSchedulers {
            scheduler.invalidate()
            Logger.process.info("GlobalTimer: Invalidated background scheduler for '\(profileName, privacy: .public)'")
        }

        backgroundSchedulers.removeAll()
        schedules.removeAll()

        // Cancel any pending wake check to avoid a no-op shortly after.
        wakeCheckTask?.cancel()
        wakeCheckTask = nil

        scheduleNextForegroundTimer()
        Logger.process.info("GlobalTimer: All schedules cleared")
    }

    /// Optional: Call on app termination to drop observers and pending tasks.
    public func cleanup() {
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

    /// Schedules a one-shot foreground timer for the nearest due schedule.
    /// If an item is already due, executes immediately and reschedules.
    private func scheduleNextForegroundTimer() {
        // Always invalidate any existing timer before scheduling a new one.
        timer?.invalidate()
        timer = nil

        guard let nextEntry = schedules.min(by: { $0.value.time < $1.value.time }) else {
            Logger.process.info("GlobalTimer: No schedules, foreground timer not needed")
            return
        }

        let nextItem = nextEntry.value
        let nextTime = nextItem.time

        let now = Date.now
        let interval = nextTime.timeIntervalSince(now)

        if interval <= 0 {
            Logger.process.info("GlobalTimer: Next schedule already due, executing now")
            checkSchedules()
            // After executing, if more schedules remain, schedule again.
            if !schedules.isEmpty {
                scheduleNextForegroundTimer()
            }
            return
        }

        let timerTolerance = resolveTimerTolerance(requested: nextItem.tolerance, interval: interval)
        Logger.process.info("GlobalTimer: Scheduling one-shot foreground timer in \(interval, privacy: .public) seconds (tolerance \(timerTolerance, privacy: .public)s)")
        let t = Timer(timeInterval: interval, repeats: false) { [weak self] _ in
            Task { @MainActor in
                guard let self else { return }
                self.checkSchedules()
                // Schedule the next one if there are more schedules.
                self.scheduleNextForegroundTimer()
            }
        }
        t.tolerance = timerTolerance
        RunLoop.main.add(t, forMode: .common)
        timer = t
    }

    /// Checks all schedules and executes any that are due.
    @objc private func checkSchedules() {
        let now = Date.now
        var dueProfiles: [String] = []

        for (profileName, item) in schedules {
            Logger.process.info("GlobalTimer: Checking '\(profileName, privacy: .public)' - now: \(now, privacy: .public), scheduled: \(item.time, privacy: .public)")
            if now >= item.time {
                Logger.process.info("GlobalTimer: Executing schedule for '\(profileName, privacy: .public)'")
                // Expose currently executing profile
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
    }

    /// Executes a schedule if it's still current (not replaced by a newer schedule).
    private func executeScheduleIfCurrent(profileName: String, scheduledTime: Date) {
        guard let item = schedules[profileName] else {
            Logger.process.info("GlobalTimer: No schedule found for '\(profileName, privacy: .public)'")
            return
        }

        guard item.time == scheduledTime, Date.now >= item.time else {
            Logger.process.info("GlobalTimer: Skipping stale or not-yet-due schedule for '\(profileName, privacy: .public)'")
            return
        }

        Logger.process.info("GlobalTimer: Executing callback for '\(profileName, privacy: .public)'")
        // Expose currently executing profile
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
                self.scheduleNextForegroundTimer()
            }
        }
    }

    // MARK: - Tolerance helpers

    /// Normalizes a requested tolerance (clamps negative to 0).
    private func normalizedTolerance(_ requested: TimeInterval?) -> TimeInterval? {
        guard let requested else { return nil }
        return max(0, requested)
    }

    /// Resolve default tolerance for background scheduler when none is requested.
    private func defaultBackgroundTolerance(for interval: TimeInterval) -> TimeInterval {
        // Reasonable flexibility for system optimization.
        // At least 5s, at most 60s, ~10% of interval otherwise.
        return min(60, max(5, interval / 10))
    }

    /// Resolve default tolerance for foreground one-shot timer when none is requested.
    private func defaultTimerTolerance(for interval: TimeInterval) -> TimeInterval {
        // Allow small drift to coalesce timers; at least 1s, at most 60s, ~10% of interval otherwise.
        return min(60, max(1, interval / 10))
    }

    private func resolveBackgroundTolerance(requested: TimeInterval?, interval: TimeInterval) -> TimeInterval {
        let req = normalizedTolerance(requested) ?? defaultBackgroundTolerance(for: interval)
        // Don't exceed half of the interval to keep reasonable precision for very near events.
        return min(req, max(0, interval / 2))
    }

    private func resolveTimerTolerance(requested: TimeInterval?, interval: TimeInterval) -> TimeInterval {
        let req = normalizedTolerance(requested) ?? defaultTimerTolerance(for: interval)
        return min(req, max(0, interval / 2))
    }
}
