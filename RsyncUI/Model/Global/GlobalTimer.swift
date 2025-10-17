import AppKit
import Foundation
import Observation
import OSLog

@Observable
@MainActor
public final class GlobalTimer {
    public static let shared = GlobalTimer()

    // MARK: - Types

    // The callback is set in ObservableFutureSchedules and when
    // callback is executed at time t, it upadtes the profilename
    // which trigger executin by URL (SidebarMainView) and
    // recomputes scheduled tasks
    /*
     // The Callback for Schedule
     let callback: () -> Void = {
         self.recomputeschedules()
         self.setfirsscheduledate()
         // Setting profile name will trigger execution
         self.scheduledprofile = schedule.profile ?? "Default"
         Task {
             // Logging to file that a Schedule is fired
             await ActorLogToFile(command: "Schedule", stringoutputfromrsync: ["ObservableFutureSchedules: schedule FIRED for \(schedule.profile ?? "Default")"])
         }
     }
     */
    
    struct ScheduledItem: Identifiable, Hashable {
        let id = UUID()
        let time: Date
        let tolerance: TimeInterval
        let callback: () -> Void

        static func == (lhs: ScheduledItem, rhs: ScheduledItem) -> Bool {
            // Compare identity and schedule-relevant fields; ignore the closure
            return lhs.id == rhs.id && lhs.time == rhs.time && lhs.tolerance == rhs.tolerance
        }

        func hash(into hasher: inout Hasher) {
            // Hash only stable, hashable properties; ignore the closure
            hasher.combine(id)
            hasher.combine(time)
            hasher.combine(tolerance)
        }
    }

    // MARK: - Properties

    @ObservationIgnored
    private var timer: Timer?

    @ObservationIgnored
    private var wakeObserver: NSObjectProtocol?
    // Dictionary to store most recent, not excuted Schedule
    // private var schedule: [String: ScheduledItem] = [:]
    // Store all schedules
    @ObservationIgnored
    private var allSchedules: [UUID: ScheduledItem] = [:]

    // MARK: - Initialization

    private init() {
        setupWakeNotification()
    }

    // MARK: - Public API
    /*
    private func removefromallSchedules(_ schedule: [UUID: ScheduledItem]) {
        if let key = schedule.keys.first {
            self.allSchedules.removeValue(forKey: key)
        }
    }
    
     */
    private func appendallSchedules(_ schedule: [UUID: ScheduledItem]) {
        for (key, value) in schedule {
            self.allSchedules[key] = value
        }
    }

    public func timerIsActive() -> Bool {
        timer != nil
    }

    public func nextScheduleDate(format: Date.FormatStyle = .dateTime) -> String? {
        let earliest = allSchedules.values.min(by: { $0.time < $1.time })
        return earliest?.time.formatted(format)
    }

    /// Schedule a task to run at a specific time
    /// - Parameters:
    ///   - time: Target execution time
    ///   - tolerance: Tolerance in seconds (defaults to 10% of interval, min 1s, max 60s)
    ///   - callback: Closure to execute when due
    public func addSchedule(
        time: Date,
        tolerance: TimeInterval? = nil,
        callback: @escaping () -> Void
    ) {
        
        let interval = time.timeIntervalSince(.now)
        let finalTolerance = tolerance ?? defaultTolerance(for: interval)
        // UUID is also set in ScheduledItem
        let schedule = ScheduledItem (
            time: time,
            tolerance: max(0, finalTolerance),
            callback: callback
        )
        let scheduleitem : [UUID:ScheduledItem] = [schedule.id:schedule]
        
        Logger.process.info("GlobalTimer: Adding NEW schedule for at \(time, privacy: .public) (tolerance: \(finalTolerance, privacy: .public)s)")
        
        appendallSchedules(scheduleitem)
        scheduleNextTimer()
    }

    public func clearSchedules() {
        guard !allSchedules.isEmpty else { return }
        Logger.process.info("GlobalTimer: Clearing all schedules")
        allSchedules.removeAll()
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

        // let earliest = allSchedules.values.min(by: { $0.time < $1.time })
        guard let item = allSchedules.values.min(by: { $0.time < $1.time }) else {
            // Schedule is removed in func executeSchedule(profileName: String)
            Logger.process.info("GlobalTimer: No task to schedule for execution")
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

    // This function is triggered at time t, it finds the apporiate callback and executes it
    // The executeSchedule(id: UUID) also removes the Scheduled task from allSchedules, leaving next
    // due tasks in Set.
    private func checkSchedules() {
        
        let now = Date.now
        
        let duetask = allSchedules.filter { now >= $0.value.time }.map { $0.key }
        Logger.process.info("GlobalTimer: checkSchedules(), DUE profile schedule: \(duetask, privacy: .public)")
        guard !duetask.isEmpty else {
            timer?.invalidate()
            timer = nil
            return
        }

        // Execute only the first eligible profile, use UUID to select task
        if let duetaskid = duetask.first {
            executeSchedule(id: duetaskid)
        }

        scheduleNextTimer()
    }

    private func executeSchedule(id: UUID) {
        guard let item = allSchedules.removeValue(forKey: id) else {
            timer?.invalidate()
            timer = nil
            return
        }
        Logger.process.info("GlobalTimer: EXCUTING schedule for '\(id, privacy: .public)'")
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
        Logger.process.info("GlobalTimer: handleWake(), system woke up, checking for past-due schedules")
        checkSchedules()
    }

    // MARK: - Helpers

    private func defaultTolerance(for interval: TimeInterval) -> TimeInterval {
        min(60, max(1, interval * 0.1))
    }
}
