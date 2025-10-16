import AppKit
import Foundation
import Observation
import OSLog

/// A main-actor, power-friendly, singleton timer that coalesces all scheduled tasks
/// across profiles into a single Timer on the main run loop.
///
/// Key features:
/// - Single `Timer` instance powering all schedules
/// - Multiple tasks per profile via task IDs
/// - Per-profile throttling (minimum time between executions)
/// - Inter-profile spacing to avoid many profiles firing at once
/// - Wake handling using `NSWorkspace.didWakeNotification`
/// - Timer tolerance to help the system coalesce wakeups
@Observable
@MainActor
public final class GlobalTimer {
    /// Shared singleton instance.
    public static let shared = GlobalTimer()

    // MARK: - Types

    /// One scheduled task.
    private struct ScheduledItem {
        /// Target time to execute.
        var time: Date
        /// Allowed timer tolerance to save power.
        let tolerance: TimeInterval
        /// Closure to execute when due. Executed on the main actor.
        let callback: () -> Void
    }

    // MARK: - Properties

    /// The single underlying timer. Ignored by Observation so UI doesn’t re-render on timer churn.
    @ObservationIgnored
    private var timer: Timer?

    /// Observer token for system wake notifications. Ignored by Observation.
    @ObservationIgnored
    private var wakeObserver: NSObjectProtocol?

    /// All scheduled tasks grouped by profile, keyed by UUID task IDs.
    /// - Key: profile name (e.g. "Default")
    /// - Value: map of taskID -> ScheduledItem
    private var schedules: [String: [UUID: ScheduledItem]] = [:]

    /// Tracks the last execution time per profile (for throttling).
    private var lastExecutionTime: [String: Date] = [:]

    /// Minimum time between executions in the same profile (seconds).
    private let minimumExecutionInterval: TimeInterval = 5 * 60 // 5 minutes

    // MARK: - Initialization

    private init() {
        setupWakeNotification()
    }

    // MARK: - Public API

    /// Indicates whether an active timer is currently scheduled.
    public func timerIsActive() -> Bool {
        timer != nil
    }

    /// Returns the earliest scheduled time across all tasks as a formatted string.
    /// - Parameter format: The `Date.FormatStyle` used to format the date.
    /// - Returns: A formatted string, or nil if there are no scheduled tasks.
    public func nextScheduleDate(format: Date.FormatStyle = .dateTime) -> String? {
        let nextDate: Date? = schedules.values
            .flatMap { $0.values }
            .map { $0.time }
            .min()
        return nextDate?.formatted(format)
    }

    /// Adds a scheduled task.
    ///
    /// - Parameters:
    ///   - profile: Optional profile identifier. Defaults to "Default".
    ///   - time: When the task should run.
    ///   - tolerance: Optional tolerance (seconds). Defaults to 10% of the interval, clamped to [1s, 60s].
    ///   - callback: Closure to execute on the main actor when due.
    public func addSchedule(
        profile: String? = nil,
        time: Date,
        tolerance: TimeInterval? = nil,
        callback: @escaping () -> Void
    ) {
        let profileName = profile ?? "Default"
        let interval = time.timeIntervalSince(.now)
        let finalTolerance = tolerance ?? defaultTolerance(for: interval)

        let taskID = UUID()
        let item = ScheduledItem(
            time: time,
            tolerance: max(0, finalTolerance),
            callback: callback
        )

        if schedules[profileName] == nil {
            schedules[profileName] = [:]
        }
        schedules[profileName]?[taskID] = item

        Logger.process.info("GlobalTimer: Adding schedule for '\(profileName)' at \(time) (tolerance: \(finalTolerance)s, taskID: \(taskID))")

        scheduleNextTimer()
    }

    /// Removes all scheduled tasks for a given profile (if any), then reschedules the timer.
    /// - Parameter profile: Profile name key (e.g., "Default").
    public func removeSchedule(profile: String) {
        if schedules.removeValue(forKey: profile) != nil {
            Logger.process.info("GlobalTimer: Removed schedule for '\(profile)'")
            scheduleNextTimer()
        }
    }

    /// Clears all scheduled tasks, if any, and reschedules the timer (which will deactivate).
    public func clearSchedules() {
        guard !schedules.isEmpty else { return }
        Logger.process.info("GlobalTimer: Clearing all schedules")
        schedules.removeAll()
        scheduleNextTimer()
    }

    /// Unhooks wake observation and invalidates the timer.
    public func cleanup() {
        if let observer = wakeObserver {
            NSWorkspace.shared.notificationCenter.removeObserver(observer)
            wakeObserver = nil
        }
        timer?.invalidate()
        timer = nil
    }

    // MARK: - Private

    /// Schedules the underlying `Timer` for the earliest due task across all profiles.
    /// Applies immediate execution for overdue items and re-arms for the next one.
    private func scheduleNextTimer() {
        // Cancel any existing timer
        timer?.invalidate()
        timer = nil

        // Find the earliest task across all profiles
        var nextProfileName: String?
        var nextTaskID: UUID?
        var nextItem: ScheduledItem?

        for (profile, tasks) in schedules {
            for (taskID, item) in tasks {
                if let current = nextItem {
                    if item.time < current.time {
                        nextProfileName = profile
                        nextTaskID = taskID
                        nextItem = item
                    }
                } else {
                    nextProfileName = profile
                    nextTaskID = taskID
                    nextItem = item
                }
            }
        }

        guard let profileName = nextProfileName, let taskID = nextTaskID, let item = nextItem else {
            Logger.process.info("GlobalTimer: No schedules")
            return
        }

        let interval = item.time.timeIntervalSince(.now)

        // Execute immediately if already due
        if interval <= 0 {
            Logger.process.info("GlobalTimer: Schedule '\(profileName)' already due, executing now")
            executeSchedule(profileName: profileName, taskID: taskID)
            scheduleNextTimer() // Schedule next if any remain
            return
        }

        Logger.process.info("GlobalTimer: Scheduling timer in \(interval)s (tolerance: \(item.tolerance)s)")

        let t = Timer(timeInterval: interval, repeats: false) { [weak self] _ in
            Task { @MainActor in
                self?.checkSchedules()
            }
        }
        t.tolerance = item.tolerance
        RunLoop.main.add(t, forMode: .common)
        timer = t
    }

    /// Scans for due tasks and applies throttling and inter-profile spacing before executing or rescheduling.
    private func checkSchedules() {
        let now = Date.now

        // Collect due tasks per profile
        var profilesWithDueTasks: [String: [(taskID: UUID, item: ScheduledItem)]] = [:]
        for (profileName, tasks) in schedules {
            let dueTasks = tasks.filter { now >= $0.value.time }
            if !dueTasks.isEmpty {
                profilesWithDueTasks[profileName] = dueTasks.map { (taskID: $0.key, item: $0.value) }
            }
        }
        guard !profilesWithDueTasks.isEmpty else { return }

        // Split profiles into eligible vs throttled (per-profile spacing)
        var eligibleProfiles: [String] = []
        var throttledProfiles: [String] = []

        for profileName in profilesWithDueTasks.keys {
            if let lastExecution = lastExecutionTime[profileName] {
                let timeSinceLastExecution = now.timeIntervalSince(lastExecution)
                if timeSinceLastExecution < minimumExecutionInterval {
                    throttledProfiles.append(profileName)
                    Logger.process.debug("GlobalTimer: Throttling profile '\(profileName)' - last executed \(Int(timeSinceLastExecution))s ago, need \(Int(self.minimumExecutionInterval))s")
                } else {
                    eligibleProfiles.append(profileName)
                }
            } else {
                eligibleProfiles.append(profileName)
            }
        }

        // Reschedule throttled profiles to their next allowed time
        for profileName in throttledProfiles {
            guard let tasks = profilesWithDueTasks[profileName],
                  let lastExecution = lastExecutionTime[profileName] else { continue }

            let nextAllowedTime = lastExecution.addingTimeInterval(minimumExecutionInterval)
            for (taskID, _) in tasks {
                if var item = schedules[profileName]?[taskID], nextAllowedTime > now {
                    item.time = nextAllowedTime
                    schedules[profileName]?[taskID] = item
                    Logger.process.debug("GlobalTimer: Rescheduled task \(taskID) for '\(profileName)' to \(nextAllowedTime)")
                }
            }
        }

        // For eligible profiles, run one task now and space others 5-min apart per profile
        if !eligibleProfiles.isEmpty {
            let sortedProfiles = eligibleProfiles.sorted()
            for (index, profileName) in sortedProfiles.enumerated() {
                guard let tasks = profilesWithDueTasks[profileName] else { continue }
                let sortedTasks = tasks.sorted { $0.item.time < $1.item.time }

                if index == 0 {
                    // Execute earliest task immediately
                    let firstTask = sortedTasks.first!
                    executeSchedule(profileName: profileName, taskID: firstTask.taskID)
                    /*

                    // Push remaining due tasks in this profile by minimumExecutionInterval
                    for task in sortedTasks.dropFirst() {
                        if var item = schedules[profileName]?[task.taskID] {
                            item.time = now.addingTimeInterval(minimumExecutionInterval)
                            schedules[profileName]?[task.taskID] = item
                            Logger.process.info("GlobalTimer: Rescheduled additional task \(task.taskID) for profile '\(profileName)' to maintain per-profile spacing")
                        }
                    }
                     */
                } else {
                    // Space subsequent profiles by index * 5 minutes
                    let delayMinutes = index * 5
                    let executeTime = now.addingTimeInterval(TimeInterval(delayMinutes * 60))

                    // Move earliest task for this profile to executeTime
                    let firstTask = sortedTasks.first!
                    if var item = schedules[profileName]?[firstTask.taskID] {
                        item.time = executeTime
                        schedules[profileName]?[firstTask.taskID] = item
                        Logger.process.info("GlobalTimer: Scheduled profile '\(profileName)' to execute in \(delayMinutes) minutes")
                    }
                    
                    /*
                    // Push other due tasks by an additional 5 minutes after first
                    for task in sortedTasks.dropFirst() {
                        if var item = schedules[profileName]?[task.taskID] {
                            item.time = executeTime.addingTimeInterval(minimumExecutionInterval)
                            schedules[profileName]?[task.taskID] = item
                            Logger.process.info("GlobalTimer: Rescheduled additional task \(task.taskID) for profile '\(profileName)'")
                        }
                    }
                     */
                }
            }
        }

        cleanupOldExecutionTimes()
        scheduleNextTimer()
    }

    /// Executes and removes a scheduled task, records last execution time for throttling.
    private func executeSchedule(profileName: String, taskID: UUID) {
        guard let item = schedules[profileName]?[taskID] else { return }

        // Remove task
        schedules[profileName]?.removeValue(forKey: taskID)
        if schedules[profileName]?.isEmpty == true {
            schedules.removeValue(forKey: profileName)
        }

        // Record per-profile execution time
        lastExecutionTime[profileName] = Date.now

        Logger.process.info("GlobalTimer: Executing task \(taskID) for profile '\(profileName)'")
        item.callback()
    }

    /// Periodically removes stale entries (older than 24 hours) from `lastExecutionTime`.
    private func cleanupOldExecutionTimes() {
        let cutoffTime = Date.now.addingTimeInterval(-24 * 60 * 60)
        let beforeCount = lastExecutionTime.count
        lastExecutionTime = lastExecutionTime.filter { _, date in date > cutoffTime }
        let removedCount = beforeCount - lastExecutionTime.count
        if removedCount > 0 {
            Logger.process.debug("GlobalTimer: Cleaned up \(removedCount) old execution time entries")
        }
    }

    // MARK: - Wake Handling

    /// Observes system wake to re-check schedules promptly after sleep.
    private func setupWakeNotification() {
        wakeObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didWakeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.handleWake()
            }
        }
    }

    /// Handler invoked after system wake.
    private func handleWake() {
        Logger.process.info("GlobalTimer: System woke, checking schedules")
        checkSchedules()
    }

    // MARK: - Helpers

    /// Default tolerance is 10% of the interval, clamped to [1s, 60s].
    private func defaultTolerance(for interval: TimeInterval) -> TimeInterval {
        min(60, max(1, interval * 0.1))
    }
}
