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
        let tolerance: TimeInterval
        let callback: () -> Void
    }

    // MARK: - Properties

    /// Foreground one-shot timer for the nearest due schedule.
    @ObservationIgnored
    private var timer: Timer?

    /// Observer token for system wake notifications.
    @ObservationIgnored
    private var wakeObserver: NSObjectProtocol?

    /// All scheduled tasks keyed by profile name.
    private var schedules: [String: ScheduledItem] = [:]

    // MARK: - Initialization

    private init() {
        setupWakeNotification()
    }

    // MARK: - Public API

    /// Schedule a task for a profile to run at an exact time.
    /// - Parameters:
    ///   - profile: Profile identifier (defaults to "Default").
    ///   - time: Target execution time.
    ///   - tolerance: Timing tolerance in seconds. Pass 0 for maximum precision.
    ///                Defaults to ~10% of interval (min 1s, max 60s) for power efficiency.
    ///   - callback: Closure executed when due. Errors are caught and logged.
    public func addSchedule(
        profile: String = "Default",
        time: Date,
        tolerance: TimeInterval? = nil,
        callback: @escaping () -> Void
    ) {
        Logger.process.info("GlobalTimer: Adding schedule for '\(profile, privacy: .public)' at \(time, privacy: .public)")

        let resolvedTolerance = resolveToleranceForSchedule(requested: tolerance, time: time)
        
        // Store or replace the schedule.
        schedules[profile] = ScheduledItem(
            time: time,
            tolerance: resolvedTolerance,
            callback: callback
        )

        // Refresh the foreground timer to account for new schedule.
        scheduleNextForegroundTimer()
    }

    /// Remove an existing schedule for a given profile, if any.
    public func removeSchedule(profile: String) {
        guard schedules.removeValue(forKey: profile) != nil else {
            Logger.process.info("GlobalTimer: No schedule to remove for '\(profile, privacy: .public)'")
            return
        }
        
        Logger.process.info("GlobalTimer: Removed schedule for '\(profile, privacy: .public)'")
        scheduleNextForegroundTimer()
    }

    /// Clears all scheduled tasks and invalidates all timers.
    public func clearSchedules() {
        guard !schedules.isEmpty else {
            Logger.process.info("GlobalTimer: No schedules to clear")
            return
        }

        Logger.process.info("GlobalTimer: Clearing all schedules")
        schedules.removeAll()
        timer?.invalidate()
        timer = nil
    }
    
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

    /// Call on app termination to clean up observers and timers.
    public func cleanup() {
        if let observer = wakeObserver {
            Logger.process.info("GlobalTimer: Removing wake notification observer")
            NSWorkspace.shared.notificationCenter.removeObserver(observer)
            wakeObserver = nil
        }
        timer?.invalidate()
        timer = nil
        schedules.removeAll()
    }

    // MARK: - Private

    /// Schedules a one-shot foreground timer for the nearest due schedule.
    /// If an item is already due, executes immediately and reschedules.
    private func scheduleNextForegroundTimer() {
        // Always invalidate any existing timer before scheduling a new one.
        timer?.invalidate()
        timer = nil

        guard let (nextProfile, nextItem) = schedules.min(by: { $0.value.time < $1.value.time }) else {
            Logger.process.info("GlobalTimer: No schedules remaining")
            return
        }

        let now = Date.now
        let interval = nextItem.time.timeIntervalSince(now)

        // If already due, execute immediately and reschedule.
        if interval <= 0 {
            Logger.process.info("GlobalTimer: Schedule for '\(nextProfile, privacy: .public)' already due, executing now")
            executeSchedule(profile: nextProfile, item: nextItem)
            schedules.removeValue(forKey: nextProfile)
            
            // Reschedule if more schedules remain.
            if !schedules.isEmpty {
                scheduleNextForegroundTimer()
            }
            return
        }

        // Schedule timer for future execution.
        Logger.process.info("GlobalTimer: Scheduling timer for '\(nextProfile, privacy: .public)' in \(interval, privacy: .public)s (tolerance \(nextItem.tolerance, privacy: .public)s)")
        
        let t = Timer(timeInterval: interval, repeats: false) { [weak self] _ in
            Task { @MainActor in
                self?.checkAndExecuteDueSchedules()
            }
        }
        t.tolerance = nextItem.tolerance
        RunLoop.main.add(t, forMode: .common)
        timer = t
    }

    /// Checks all schedules and executes any that are due.
    private func checkAndExecuteDueSchedules() {
        let now = Date.now
        var executedProfiles: [String] = []

        for (profile, item) in schedules where now >= item.time {
            Logger.process.info("GlobalTimer: Executing schedule for '\(profile, privacy: .public)'")
            executeSchedule(profile: profile, item: item)
            executedProfiles.append(profile)
        }

        // Remove executed schedules.
        for profile in executedProfiles {
            schedules.removeValue(forKey: profile)
        }

        // Schedule next timer if schedules remain.
        if !schedules.isEmpty {
            scheduleNextForegroundTimer()
        }
    }

    /// Executes a schedule's callback.
    private func executeSchedule(profile: String, item: ScheduledItem) {
        item.callback()
    }

    // MARK: - Wake handling

    private func setupWakeNotification() {
        guard wakeObserver == nil else { return }
        
        wakeObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didWakeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                guard let self else { return }
                Logger.process.info("GlobalTimer: System woke up, checking for missed schedules")
                self.checkAndExecuteDueSchedules()
            }
        }
        
        Logger.process.info("GlobalTimer: Wake notification observer registered")
    }

    // MARK: - Tolerance calculation

    /// Resolves the tolerance to use for a schedule.
    private func resolveToleranceForSchedule(requested: TimeInterval?, time: Date) -> TimeInterval {
        // If explicitly requested, use it (clamped to non-negative).
        if let requested = requested {
            return max(0, requested)
        }
        
        // Otherwise calculate a reasonable default based on time until execution.
        let interval = time.timeIntervalSince(Date.now)
        guard interval > 0 else { return 0 }
        
        // Default: 10% of interval, capped between 1s and 60s.
        let defaultTolerance = interval * 0.1
        return min(60, max(1, defaultTolerance))
    }
}
