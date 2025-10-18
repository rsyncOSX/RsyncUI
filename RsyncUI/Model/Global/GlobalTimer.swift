import AppKit
import Foundation
import Observation
import OSLog

// MARK: - Types
 
struct ScheduledItem: Identifiable, Hashable {
    public let id = UUID()
    let time: Date
    let tolerance: TimeInterval
    let callback: () -> Void
    var scheduledata: SchedulesConfigurations?

    public static func == (lhs: ScheduledItem, rhs: ScheduledItem) -> Bool {
        // Compare identity and schedule-relevant fields; ignore the closure
        lhs.id == rhs.id && lhs.time == rhs.time && lhs.tolerance == rhs.tolerance
    }

    public func hash(into hasher: inout Hasher) {
        // Hash only stable, hashable properties; ignore the closure
        hasher.combine(id)
        hasher.combine(time)
        hasher.combine(tolerance)
    }
}

@Observable
@MainActor
public final class GlobalTimer {
    public static let shared = GlobalTimer()

    // Exposed Array of not excuted Schedule
    var allSchedules = [ScheduledItem]()

    // MARK: - Properties

    @ObservationIgnored
    private var timer: Timer?
    @ObservationIgnored
    private var wakeObserver: NSObjectProtocol?

    // MARK: - Initialization

    private init() {
        setupWakeNotification()
    }

    // MARK: - Public API

    // Verifying that there is a schedule in Set already, if false add schedule
    // to set.
    private func validatescheduleinset(_ schedule: ScheduledItem) -> Bool {
        let validate = allSchedules.contains(where: { $0.time == schedule.time && $0.tolerance == schedule.tolerance })
        return validate
    }

    // Check if there already is a timer in Set which more recent time which already is
    // in Set. If false it executes the scheduleNextTimer.
    private func validateallschedulesalreadyintimer(_ schedule: ScheduledItem) -> Bool {
        let validate = allSchedules.contains(where: { $0.time < schedule.time })
        return validate
    }

    public func timerIsActive() -> Bool {
        timer != nil
    }

    public func nextScheduleDate(format: Date.FormatStyle = .dateTime) -> String? {
        let earliest = allSchedules.min(by: { $0.time < $1.time })
        return earliest?.time.formatted(format)
    }

    func invaldiateallschedulesandtimer() {
        Logger.process.info("GlobalTimer: INVALIDATING all schedules")
        timer?.invalidate()
        timer = nil
        allSchedules.removeAll()
    }

    /// Schedule a task to run at a specific time
    /// - Parameters:
    ///   - time: Target execution time
    ///   - tolerance: Tolerance in seconds (defaults to 10% of interval, min 1s, max 60s)
    ///   - callback: Closure to execute when due
    func addSchedule(
        time: Date,
        tolerance: TimeInterval? = nil,
        callback: @escaping () -> Void,
        scheduledata: SchedulesConfigurations?
    ) {
        let interval = time.timeIntervalSince(.now)
        let finalTolerance = tolerance ?? defaultTolerance(for: interval)
        // UUID is also set in ScheduledItem
        let scheduleitem = ScheduledItem(
            time: time,
            tolerance: max(0, finalTolerance),
            callback: callback,
            scheduledata: scheduledata
        )
        guard validatescheduleinset(scheduleitem) == false else { return }
        Logger.process.info("GlobalTimer: Adding NEW schedule for at \(time, privacy: .public) (tolerance: \(finalTolerance, privacy: .public)s)")

        // Append and sort by time
        allSchedules.append(scheduleitem)
        allSchedules = allSchedules.sorted(by: { $0.time < $1.time })

        if validateallschedulesalreadyintimer(scheduleitem) == false {
            scheduleNextTimer()
        }
    }

    public func cleanup() {
        if let observer = wakeObserver {
            NSWorkspace.shared.notificationCenter.removeObserver(observer)
            wakeObserver = nil
        }
        timer?.invalidate()
        timer = nil
    }

    public func scheduleNextTimer() {
        timer?.invalidate()
        timer = nil

        guard allSchedules.isEmpty == false else {
            Logger.process.info("GlobalTimer: No more tasks to schedule for execution")
            invaldiateallschedulesandtimer()
            return
        }

        if let item = allSchedules.first {
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
    }

    // MARK: - Private

    // This function is triggered at time t, it finds the apporiate callback and executes it
    private func checkSchedules() {
        if let item = allSchedules.first {
            if allSchedules.count > 0 {
                allSchedules.removeFirst()
            }
            executeSchedule(item)
        } else {
            Logger.process.info("GlobalTimer: No more tasks to schedule for execution")
            invaldiateallschedulesandtimer()
        }
    }

    private func executeSchedule(_ dueitem: ScheduledItem) {
        Logger.process.info("GlobalTimer: EXCUTING schedule for '\(dueitem.scheduledata?.profile ?? "Default", privacy: .public)'")
        dueitem.callback()
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
        Logger.process.info("GlobalTimer: handleWake(), system woke up, checking for past-due schedules")
        checkSchedules()
    }

    // MARK: - Helpers

    private func defaultTolerance(for interval: TimeInterval) -> TimeInterval {
        min(60, max(1, interval * 0.1))
    }
}
