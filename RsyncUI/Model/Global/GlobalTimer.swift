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
        var time: Date
        let tolerance: TimeInterval
        let callback: () -> Void
    }

    // MARK: - Properties

    @ObservationIgnored
    private var timer: Timer?

    @ObservationIgnored
    private var wakeObserver: NSObjectProtocol?

    private var schedules: [String: ScheduledItem] = [:]

    private var lastExecutionTime: [String: Date] = [:]
    private let minimumExecutionInterval: TimeInterval = 5 * 60 // 5 minutes in seconds

    // Track wake state
    private var isHandlingWake = false

    // MARK: - Initialization

    private init() {
        setupWakeNotification()
    }

    // MARK: - Public API

    public func timerIsActive() -> Bool {
        timer != nil
    }

    public func nextScheduleDate(format: Date.FormatStyle = .dateTime) -> String? {
        schedules.values.min(by: { $0.time < $1.time })?.time.formatted(format)
    }

    /// Schedule a task to run at a specific time
    /// - Parameters:
    ///   - profile: Profile identifier (defaults to "Default")
    ///   - time: Target execution time
    ///   - tolerance: Tolerance in seconds (defaults to 10% of interval, min 1s, max 60s)
    ///   - callback: Closure to execute when due
    public func addSchedule(
        profile: String? = nil,
        time: Date,
        tolerance: TimeInterval? = nil,
        callback: @escaping () -> Void
    ) {
        let profileName = profile ?? "Default"
        let interval = time.timeIntervalSince(.now)
        let finalTolerance = tolerance ?? defaultTolerance(for: interval)

        Logger.process.info("GlobalTimer: Adding schedule for '\(profileName)' at \(time) (tolerance: \(finalTolerance)s)")

        schedules[profileName] = ScheduledItem(
            time: time,
            tolerance: max(0, finalTolerance),
            callback: callback
        )

        scheduleNextTimer()
    }

    public func removeSchedule(profile: String) {
        if schedules.removeValue(forKey: profile) != nil {
            Logger.process.info("GlobalTimer: Removed schedule for '\(profile)'")
            scheduleNextTimer()
        }
    }

    public func clearSchedules() {
        guard !schedules.isEmpty else { return }
        Logger.process.info("GlobalTimer: Clearing all schedules")
        schedules.removeAll()
        // Activating next present schedule
        scheduleNextTimer()
    }

    public func cleanup() {
        if let observer = wakeObserver {
            NSWorkspace.shared.notificationCenter.removeObserver(observer)
            wakeObserver = nil
        }
        timer?.invalidate()
        timer = nil
    }

    // MARK: - Private

    private func scheduleNextTimer() {
        timer?.invalidate()
        timer = nil

        guard let (_, item) = schedules.min(by: { $0.value.time < $1.value.time }) else {
            Logger.process.info("GlobalTimer: No schedules")
            return
        }

        let interval = item.time.timeIntervalSince(.now)

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

    private func checkSchedules() {
        let now = Date.now
        let dueProfiles = schedules.filter { now >= $0.value.time }.map(\.key)

        guard !dueProfiles.isEmpty else { return }

        // If handling wake, reschedule all past-due items instead of executing
        if isHandlingWake {
            Logger.process.info("GlobalTimer: Wake handling - rescheduling \(dueProfiles.count) past-due schedules")

            for profileName in dueProfiles {
                guard var item = schedules[profileName] else { continue }

                // Calculate new schedule time: minimum interval from now
                let newTime = now.addingTimeInterval(minimumExecutionInterval)
                item.time = newTime
                schedules[profileName] = item

                Logger.process.info("GlobalTimer: Rescheduled '\(profileName)' from \(item.time) to \(newTime)")
            }

            isHandlingWake = false
            scheduleNextTimer()
            return
        }

        // Normal execution flow (not after wake)
        // Filter profiles that haven't been executed recently
        let eligibleProfiles = dueProfiles.filter { profileName in
            guard let lastExecution = lastExecutionTime[profileName] else {
                return true // Never executed, so eligible
            }
            let timeSinceLastExecution = now.timeIntervalSince(lastExecution)
            if timeSinceLastExecution < minimumExecutionInterval {
                Logger.process.debug("GlobalTimer: Skipping '\(profileName)' - executed \(Int(timeSinceLastExecution))s ago, need \(Int(self.minimumExecutionInterval))s")
                return false
            }
            return true
        }

        // Handle throttled profiles - reschedule them for minimum interval from their last execution
        let throttledProfiles = dueProfiles.filter { !eligibleProfiles.contains($0) }
        for profileName in throttledProfiles {
            if var item = schedules[profileName],
               let lastExecution = lastExecutionTime[profileName]
            {
                let nextAllowedTime = lastExecution.addingTimeInterval(minimumExecutionInterval)

                // Update the schedule time to the next allowed time
                item.time = nextAllowedTime
                schedules[profileName] = item

                Logger.process.debug("GlobalTimer: Rescheduled '\(profileName)' to \(nextAllowedTime)")
            }
        }

        // Execute only the first eligible profile
        if let firstProfile = eligibleProfiles.first {
            executeSchedule(profileName: firstProfile)
        }

        // Clean up old execution times periodically
        cleanupOldExecutionTimes()

        scheduleNextTimer()
    }

    private func executeSchedule(profileName: String) {
        guard let item = schedules.removeValue(forKey: profileName) else { return }

        // Record the execution time
        lastExecutionTime[profileName] = Date.now

        Logger.process.info("GlobalTimer: Executing schedule for '\(profileName)'")
        item.callback()
    }

    private func cleanupOldExecutionTimes() {
        let now = Date.now
        let cutoffTime = now.addingTimeInterval(-24 * 60 * 60) // Remove entries older than 24 hours

        let beforeCount = lastExecutionTime.count
        lastExecutionTime = lastExecutionTime.filter { _, date in
            date > cutoffTime
        }

        let removedCount = beforeCount - lastExecutionTime.count
        if removedCount > 0 {
            Logger.process.debug("GlobalTimer: Cleaned up \(removedCount) old execution time entries")
        }
    }

    // MARK: - Wake Handling

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

    private func handleWake() {
        Logger.process.info("GlobalTimer: System woke, checking for past-due schedules")
        isHandlingWake = true
        checkSchedules()
    }

    // MARK: - Helpers

    private func defaultTolerance(for interval: TimeInterval) -> TimeInterval {
        min(60, max(1, interval * 0.1))
    }
}
