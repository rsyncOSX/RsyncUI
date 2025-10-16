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

    @ObservationIgnored
    private var timer: Timer?

    @ObservationIgnored
    private var wakeObserver: NSObjectProtocol?
    private var schedules: [String: ScheduledItem] = [:]

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

        Logger.process.info("GlobalTimer: Adding schedule for '\(profileName, privacy: .public)' at \(time, privacy: .public) (tolerance: \(finalTolerance, privacy: .public)s)")

        schedules[profileName] = ScheduledItem(
            time: time,
            tolerance: max(0, finalTolerance),
            callback: callback
        )

        scheduleNextTimer()
    }

    public func removeSchedule(profile: String) {
        if schedules.removeValue(forKey: profile) != nil {
            Logger.process.info("GlobalTimer: Removed schedule for '\(profile, privacy: .public)'")
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

        Logger.process.info("GlobalTimer: Scheduling timer in \(interval, privacy: .public)s (tolerance: \(item.tolerance, privacy: .public)s)")

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
        
        Logger.process.info("GlobalTimer: Number of DUE schedules: \(dueProfiles.count, privacy: .public)")

        guard !dueProfiles.isEmpty else { return }

        // Execute only the first eligible profile
        if let firstProfile = dueProfiles.first {
            executeSchedule(profileName: firstProfile)
        }

        scheduleNextTimer()
    }

    private func executeSchedule(profileName: String) {
        guard let item = schedules.removeValue(forKey: profileName) else { return }
        Logger.process.info("GlobalTimer: Executing schedule for '\(profileName, privacy: .public)'")
        item.callback()
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
        checkSchedules()
    }

    // MARK: - Helpers

    private func defaultTolerance(for interval: TimeInterval) -> TimeInterval {
        min(60, max(1, interval * 0.1))
    }
}
