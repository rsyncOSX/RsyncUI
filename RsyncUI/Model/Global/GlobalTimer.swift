import AppKit
import Foundation
import Observation
import OSLog

// MARK: - Types

// The callback is set in ObservableFutureSchedules and when
// callback is executed at time t, it upadtes the profilename
// which trigger executin by URL (SidebarMainView) and
// recomputes scheduled tasks
/*
 // The Callback for Schedule
 let callback: () -> Void = {
     self.recomputeschedules()
     // Setting profile name will trigger execution
     self.scheduledprofile = schedule.profile ?? "Default"
     Task {
         // Logging to file that a Schedule is fired
         await ActorLogToFile(command: "Schedule", stringoutputfromrsync: ["ObservableFutureSchedules: schedule FIRED for \(schedule.profile ?? "Default")"])
     }
 }
 */

public struct ScheduledItem: Identifiable, Hashable {
    public let id = UUID()
    let time: Date
    let tolerance: TimeInterval
    let callback: () -> Void
    
    var profile: String?
    var dateAdded: String?
    var dateRun: String?
    var schedule: String?

    public static func == (lhs: ScheduledItem, rhs: ScheduledItem) -> Bool {
        // Compare identity and schedule-relevant fields; ignore the closure
        return lhs.id == rhs.id && lhs.time == rhs.time && lhs.tolerance == rhs.tolerance
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
    private func validateallschedulesalreadyintimer (_ schedule: ScheduledItem) -> Bool {
        let validate = allSchedules.contains(where: { $0.time < schedule.time })
        return validate
    }
    
    
    private func appendallSchedules(_ schedule: [ScheduledItem]) {
        allSchedules.append(contentsOf: schedule)
    }

    public func timerIsActive() -> Bool {
        timer != nil
    }

    public func nextScheduleDate(format: Date.FormatStyle = .dateTime) -> String? {
        let earliest = allSchedules.min(by: { $0.time < $1.time })
        return earliest?.time.formatted(format)
    }

    
    func invaldiateallschedulesandtimer() {
        Logger.process.info("GlobalTimer: Invaldidating all schedules")
        timer?.invalidate()
        timer = nil
        allSchedules.removeAll()
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
        
        guard validatescheduleinset(schedule) == false else { return }
        
        let scheduleitem : [ScheduledItem] = [schedule]
        Logger.process.info("GlobalTimer: Adding NEW schedule for at \(time, privacy: .public) (tolerance: \(finalTolerance, privacy: .public)s)")
        appendallSchedules(scheduleitem)
        
        if validateallschedulesalreadyintimer(schedule) == false {
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

    // MARK: - Private

    private func scheduleNextTimer() {
        
        timer?.invalidate()
        timer = nil

        // let earliest = allSchedules.values.min(by: { $0.time < $1.time })
        guard let item = allSchedules.min(by: { $0.time < $1.time }) else {
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
        
        let duetask = allSchedules.filter { now >= $0.time }
        Logger.process.info("GlobalTimer: checkSchedules(), DUE profile schedule: \(duetask, privacy: .public)")
        guard !duetask.isEmpty else {
            timer?.invalidate()
            timer = nil
            return
        }

        // Execute only the first eligible profile, use UUID to select task
        if let duetaskitem = duetask.first {
            executeSchedule(duetaskitem)
        }

        scheduleNextTimer()
    }

    private func executeSchedule(_ dueitem: ScheduledItem) {
        Logger.process.info("GlobalTimer: EXCUTING schedule for '\(dueitem.profile ?? "Default", privacy: .public)'")
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

