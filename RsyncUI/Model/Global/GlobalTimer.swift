import AppKit
import Foundation
import Observation
import OSLog

// MARK: - Types

struct ScheduledItem: Identifiable, Hashable {
    let id: UUID // Remove = UUID()
    var time: Date
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
        id = UUID() // Create UUID once during init
        self.time = time
        self.tolerance = tolerance
        callbackWrapper = CallbackWrapper(callback)
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
final class GlobalTimer {
    public static let shared = GlobalTimer()

    // Exposed Array of not executed Schedule
    var allSchedules = [ScheduledItem]()
    // Schedules not executed after WakeUp - func handleWake()
    @ObservationIgnored
    var notExecutedSchedulesafterWakeUp: [ScheduledItem] = []

    // MARK: - Properties

    // var scheduledata: [SchedulesConfigurations]?
    // First schedule to execute
    var firstscheduledate: SchedulesConfigurations?
    // Trigger execution
    var scheduledprofile: String = ""
    // Trigger for not executed tasks after wakeup
    var thereisnotexecutedschedulesafterwakeup: Bool = false

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

    func timerIsActive() -> Bool {
        timer != nil
    }

    func nextScheduleDate(format: Date.FormatStyle = .dateTime) -> String? {
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

    func cleanup() {
        if let observer = wakeObserver {
            NSWorkspace.shared.notificationCenter.removeObserver(observer)
            wakeObserver = nil
        }
        timer?.invalidate()
        timer = nil
    }

    func scheduleNextTimer() {
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
    
    // Only set when loading data, when new schedules added or deleted
    func setfirsscheduledate() {
        let dates = allSchedules.sorted { s1, s2 in
            if let id1 = s1.scheduledata?.dateRun?.en_date_from_string(), let id2 = s2.scheduledata?.dateRun?.en_date_from_string() {
                return id1 < id2
            }
            return false
        }
        if dates.count > 0 {
            let first = SchedulesConfigurations(profile: dates.first?.scheduledata?.profile,
                                                dateAdded: nil,
                                                dateRun: dates.first?.scheduledata?.dateRun,
                                                schedule: "")
            firstscheduledate = first
        } else {
            firstscheduledate = nil
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
        notExecutedSchedulesafterWakeUp = allSchedules.filter { $0.time.timeIntervalSinceNow < 0 }
        allSchedules.removeAll { $0.time.timeIntervalSinceNow < 0 }
        notExecutedSchedulesafterWakeUp = notExecutedSchedulesafterWakeUp.sorted(by: { $0.time < $1.time })
        if allSchedules.isEmpty {
            invalidateAllSchedulesAndTimer()
        }
        if notExecutedSchedulesafterWakeUp.isEmpty == false {
            thereisnotexecutedschedulesafterwakeup = true
        }
    }

    // MARK: - Helpers

    func defaultTolerance(for interval: TimeInterval) -> TimeInterval {
        min(60, max(1, interval * 0.1))
    }
}

extension GlobalTimer {
    func moveToSchedules(itemIDs: [ScheduledItem.ID]) {
        // Find items in notExecutedSchedulesafterWakeUp
        var itemsToMove = notExecutedSchedulesafterWakeUp.filter { itemIDs.contains($0.id) }
        // Remove from source
        notExecutedSchedulesafterWakeUp.removeAll { itemIDs.contains($0.id) }
        // Must update time with enough space in time
        // Add a 5 min timeintervall between not schduled tasks
        itemsToMove = itemsToMove.enumerated().map { index, item in
            let timeInterval = TimeInterval(index + 1) * 5 * 60
            var newItem = item
            let newTime = Date.now.addingTimeInterval(timeInterval)
            newItem.time = newTime
            newItem.scheduledata?.dateRun = newTime.en_string_from_date()
            return newItem
        }
        // Add to destination
        allSchedules.append(contentsOf: itemsToMove)
        allSchedules = allSchedules.sorted(by: { $0.time < $1.time })
        scheduleNextTimer()
        setfirsscheduledate()
    }
}
