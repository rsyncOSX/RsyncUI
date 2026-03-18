import AppKit
import Foundation
import Observation
import OSLog

// MARK: - Types

struct ScheduledItem: Identifiable, Hashable {
    let id: UUID
    var time: Date
    let tolerance: TimeInterval
    private let callbackWrapper: CallbackWrapper
    var scheduledata: SchedulesConfigurations?

    private class CallbackWrapper: Hashable {
        let callback: () -> Void
        init(_ callback: @escaping () -> Void) {
            self.callback = callback
        }
        static func == (lhs: CallbackWrapper, rhs: CallbackWrapper) -> Bool {
            lhs === rhs
        }
        func hash(into hasher: inout Hasher) {
            hasher.combine(ObjectIdentifier(self))
        }
    }

    init(time: Date, tolerance: TimeInterval, callback: @escaping () -> Void, scheduledata: SchedulesConfigurations?) {
        id = UUID()
        self.time = time
        self.tolerance = tolerance
        callbackWrapper = CallbackWrapper(callback)
        self.scheduledata = scheduledata
    }

    /// Execute the wrapped callback
    func execute() {
        callbackWrapper.callback()
    }

    /// Hashable and Equatable based on id only
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
    static let shared = GlobalTimer()

    /// Exposed Array of not executed Schedule
    var allSchedules = [ScheduledItem]()
    /// Schedules not executed after WakeUp - func handleWake()
    @ObservationIgnored
    var notExecutedSchedulesafterWakeUp: [ScheduledItem] = []

    // MARK: - Properties

    /// First schedule to execute
    var firstscheduledate: SchedulesConfigurations?
    /// Trigger execution
    var scheduledprofile: String = ""
    /// Trigger for not executed tasks after wakeup
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

    // FIX: Deduplication now uses the item's UUID (its stable identity) instead
    // of matching on time+tolerance, which could silently drop two distinct
    // schedules that happen to land on the same millisecond.
    private func validatescheduleinset(_ schedule: ScheduledItem) -> Bool {
        allSchedules.contains(where: { $0.id == schedule.id })
    }

    /// Check if there is already an earlier timer in the set.
    private func validateallschedulesalreadyintimer(_ schedule: ScheduledItem) -> Bool {
        allSchedules.contains(where: { $0.time < schedule.time })
    }

    func timerIsActive() -> Bool {
        timer != nil
    }

    func nextScheduleDate(format: Date.FormatStyle = .dateTime) -> String? {
        let earliest = allSchedules.min(by: { $0.time < $1.time })
        return earliest?.time.formatted(format)
    }

    func invalidateAllSchedulesAndTimer() {
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

        let scheduleitem = ScheduledItem(
            time: time,
            tolerance: max(0, finalTolerance),
            callback: callback,
            scheduledata: scheduledata
        )

        guard validatescheduleinset(scheduleitem) == false else { return }
        allSchedules.append(scheduleitem)
        allSchedules = allSchedules.sorted(by: { $0.time < $1.time })

        if validateallschedulesalreadyintimer(scheduleitem) == false {
            scheduleNextTimer()
        }
    }

    func scheduleNextTimer() {
        timer?.invalidate()
        timer = nil

        guard allSchedules.isEmpty == false else {
            invalidateAllSchedulesAndTimer()
            return
        }

        if let item = allSchedules.first {
            let interval = item.time.timeIntervalSince(.now)
            let timerInstance = Timer(timeInterval: interval, repeats: false) { [weak self] _ in
                Task { @MainActor in
                    self?.checkSchedules()
                }
            }
            timerInstance.tolerance = item.tolerance
            RunLoop.main.add(timerInstance, forMode: .common)
            timer = timerInstance
        }
    }

    /// Only set when loading data, when new schedules added or deleted
    func setfirsscheduledate() {
        let dates = allSchedules.sorted { firstItem, secondItem in
            if let id1 = firstItem.scheduledata?.dateRun?.en_date_from_string(),
               let id2 = secondItem.scheduledata?.dateRun?.en_date_from_string() {
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

    private func checkSchedules() {
        if let item = allSchedules.first {
            if allSchedules.count > 0 {
                allSchedules.removeFirst()
            }
            executeSchedule(item)
        } else {
            invalidateAllSchedulesAndTimer()
        }
    }

    private func executeSchedule(_ dueitem: ScheduledItem) {
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
    // FIX: `scheduledata` is a struct, so mutations on a local `var newItem`
    // copy were previously lost. The fix uses an index-based in-place update
    // via a helper mutating function on ScheduledItem, ensuring the new time
    // and dateRun string are actually stored in the array element.
    func moveToSchedules(itemIDs: [ScheduledItem.ID]) {
        var itemsToMove = notExecutedSchedulesafterWakeUp.filter { itemIDs.contains($0.id) }
        notExecutedSchedulesafterWakeUp.removeAll { itemIDs.contains($0.id) }

        // Space items 5 minutes apart starting from now
        for index in itemsToMove.indices {
            let newTime = Date.now.addingTimeInterval(TimeInterval(index + 1) * 5 * 60)
            itemsToMove[index].time = newTime
            itemsToMove[index].scheduledata?.dateRun = newTime.en_string_from_date()
        }

        allSchedules.append(contentsOf: itemsToMove)
        allSchedules = allSchedules.sorted(by: { $0.time < $1.time })
        scheduleNextTimer()
        setfirsscheduledate()
    }
}
