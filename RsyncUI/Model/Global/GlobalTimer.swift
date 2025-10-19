import AppKit
import Foundation
import Observation
import OSLog

// MARK: - Types
 
struct ScheduledItem: Identifiable, Hashable {
    public let id: UUID  // Remove = UUID()
    let time: Date
    let tolerance: TimeInterval
    private let callbackWrapper: CallbackWrapper
    var scheduledata: SchedulesConfigurations?
    
    private class CallbackWrapper {
        let callback: () -> Void
        init(_ callback: @escaping () -> Void) {
            self.callback = callback
        }
    }
    
    init(time: Date, tolerance: TimeInterval, callback: @escaping () -> Void, scheduledata: SchedulesConfigurations?) {
        self.id = UUID()  // Create UUID once during init
        self.time = time
        self.tolerance = tolerance
        self.callbackWrapper = CallbackWrapper(callback)
        self.scheduledata = scheduledata
    }
    
    // Execute the wrapped callback
        func execute() {
            callbackWrapper.callback()
        }
    
    // Implement Hashable based on id only
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: ScheduledItem, rhs: ScheduledItem) -> Bool {
        lhs.id == rhs.id
    }
}

@Observable
@MainActor
public final class GlobalTimer {
    public static let shared = GlobalTimer()

    // Exposed Array of not executed Schedule
    var allSchedules = [ScheduledItem]()
    // Schedules not executed after WakeUp - func handleWake()
    var notExecutedSchedulesafterWakeUp: [ScheduledItem] = []

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

    func invalidateAllSchedulesAndTimer() {
        Logger.process.info("GlobalTimer: INVALIDATING all schedules")
        timer?.invalidate()
        timer = nil
        allSchedules.removeAll()
    }

    /// Schedule a task to run at a specific time
    /// - Parameters:
    ///   - time: Target execution time
    ///   - tolerance: Tolerance in seconds (defaults to 10% of interval, min 1s, max 60s)
    ///   - callback: Closure to execute when due (use [weak self] to avoid retain cycles)
    ///   - scheduledata: Optional configuration data for the schedule
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
        
        guard validatescheduleinset(scheduleitem) == false else {
            Logger.process.info("GlobalTimer: Adding NEW schedule - already IN allSchedules")
            return
        }
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
        
        Logger.process.info("GlobalTimer: scheduleNextTimer() - Invalidateing existing timer")
        timer?.invalidate()
        timer = nil

        guard allSchedules.isEmpty == false else {
            Logger.process.info("GlobalTimer: scheduleNextTimer() - No more tasks to schedule for execution")
            invalidateAllSchedulesAndTimer()
            return
        }

        if let item = allSchedules.first {
            let interval = item.time.timeIntervalSince(.now)
            Logger.process.info("GlobalTimer: scheduleNextTimer() - Scheduling timer in \(interval, privacy: .public)s (tolerance: \(item.tolerance, privacy: .public)s)")
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

    // This function is triggered at time t, it finds the appropriate callback and executes it
    private func checkSchedules() {
        if let item = allSchedules.first {
            if allSchedules.count > 0 {
                allSchedules.removeFirst()
            }
            executeSchedule(item)
        } else {
            Logger.process.info("GlobalTimer: No more tasks to schedule for execution")
            invalidateAllSchedulesAndTimer()
        }
    }

    private func executeSchedule(_ dueitem: ScheduledItem) {
        Logger.process.info("GlobalTimer: EXECUTING schedule for '\(dueitem.scheduledata?.profile ?? "Default", privacy: .public)'")
        // Use the execute method instead of calling callback directly
        dueitem.execute()
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
        notExecutedSchedulesafterWakeUp.removeAll()
        Logger.process.info("GlobalTimer: handleWake(), system woke up, checking for past-due schedules")
        notExecutedSchedulesafterWakeUp = allSchedules.filter { $0.time.timeIntervalSinceNow < 0 }
        allSchedules.removeAll { $0.time.timeIntervalSinceNow < 0 }
    }
    
    /*
     
     private func handleWake() {
         Logger.process.info("GlobalTimer: handleWake(), system woke up, checking for past-due schedules")
         notExecutedSchedulesafterWakeUp.removeAll()
    
         Logger.process.info("GlobalTimer: handleWake(), system woke up, checking for past-due schedules")
         
         // checkSchedules()
         let noexecute = allSchedules.compactMap { item in
             return item.time.timeIntervalSinceNow < 0 ? item : nil
         }
         _ = noexecute.map({ item in
             notExecutedSchedulesafterWakeUp.append(item)
         })
         var indexesdelete = Set<UUID>()
         _ = notExecutedSchedulesafterWakeUp.map { item in
             indexesdelete.insert(item.id)
         }
         allSchedules.removeAll { schedule in
             indexesdelete.contains(schedule.id)
         }
     }
     
     private func handleWake() {
         Logger.process.info("GlobalTimer: handleWake(), system woke up, checking for past-due schedules")
         
         // Partition schedules into past-due and future schedules
         let (pastDue, future) = allSchedules.reduce(into: ([], [])) { result, schedule in
             if schedule.time.timeIntervalSinceNow < 0 {
                 result.0.append(schedule)
             } else {
                 result.1.append(schedule)
             }
         }
         
         notExecutedSchedulesafterWakeUp = pastDue
         allSchedules = future
     }
     
     private func handleWake() {
         Logger.process.info("GlobalTimer: handleWake(), system woke up, checking for past-due schedules")
         
         notExecutedSchedulesafterWakeUp = allSchedules.filter { $0.time.timeIntervalSinceNow < 0 }
         allSchedules.removeAll { $0.time.timeIntervalSinceNow < 0 }
     }
     */

    // MARK: - Helpers

    private func defaultTolerance(for interval: TimeInterval) -> TimeInterval {
        min(60, max(1, interval * 0.1))
    }
}
