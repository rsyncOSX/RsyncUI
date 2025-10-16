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
    
    // MARK: - Initialization

    private init() {
        setupWakeNotification()
    }

    // MARK: - Public API
    
    public func timerIsActive() -> Bool {
        timer != nil
    }
    
    // Change the schedules structure to support multiple tasks per profile
    private var schedules: [String: [UUID: ScheduledItem]] = [:]
    private var lastExecutionTime: [String: Date] = [:]
    private let minimumExecutionInterval: TimeInterval = 5 * 60 // 5 minutes in seconds

    

    // Updated addSchedule to support multiple tasks per profile
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
        let item = ScheduledItem (
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

    private func checkSchedules() {
        let now = Date.now
        
        // Find all profiles that have at least one due task
        var profilesWithDueTasks: [String: [(taskID: UUID, item: ScheduledItem)]] = [:]
        
        for (profileName, tasks) in schedules {
            let dueTasks = tasks.filter { now >= $0.value.time }
            if !dueTasks.isEmpty {
                profilesWithDueTasks[profileName] = dueTasks.map { (taskID: $0.key, item: $0.value) }
            }
        }
        
        guard !profilesWithDueTasks.isEmpty else { return }
        
        // Separate profiles into eligible and throttled
        var eligibleProfiles: [String] = []
        var throttledProfiles: [String] = []
        
        for profileName in profilesWithDueTasks.keys {
            if let lastExecution = self.lastExecutionTime[profileName] {
                let timeSinceLastExecution = now.timeIntervalSince(lastExecution)
                if timeSinceLastExecution < self.minimumExecutionInterval {
                    throttledProfiles.append(profileName)
                    Logger.process.debug("GlobalTimer: Throttling profile '\(profileName)' - last executed \(Int(timeSinceLastExecution))s ago, need \(Int(self.minimumExecutionInterval))s")
                } else {
                    eligibleProfiles.append(profileName)
                }
            } else {
                // Never executed before, so it's eligible
                eligibleProfiles.append(profileName)
            }
        }
        
        // Handle throttled profiles - reschedule their tasks
        for profileName in throttledProfiles {
            guard let tasks = profilesWithDueTasks[profileName],
                  let lastExecution = self.lastExecutionTime[profileName] else { continue }
            
            let nextAllowedTime = lastExecution.addingTimeInterval(self.minimumExecutionInterval)
            
            // Reschedule all due tasks for this profile to the next allowed time
            for (taskID, _) in tasks {
                if var item = schedules[profileName]?[taskID], nextAllowedTime > now {
                    item.time = nextAllowedTime
                    schedules[profileName]?[taskID] = item
                    Logger.process.debug("GlobalTimer: Rescheduled task \(taskID) for '\(profileName)' to \(nextAllowedTime)")
                }
            }
        }
        
        // Execute one task from each eligible profile with 5-minute spacing between profiles
        if !eligibleProfiles.isEmpty {
            // Sort profiles to maintain consistent order
            let sortedProfiles = eligibleProfiles.sorted()
            
            for (index, profileName) in sortedProfiles.enumerated() {
                guard let tasks = profilesWithDueTasks[profileName] else { continue }
                
                // Sort tasks by time to get the earliest one
                let sortedTasks = tasks.sorted { $0.item.time < $1.item.time }
                
                if index == 0 {
                    // Execute the first profile's earliest task immediately
                    let firstTask = sortedTasks.first!
                    executeSchedule(profileName: profileName, taskID: firstTask.taskID)
                    
                    // Reschedule any other due tasks for this profile to 5 minutes later
                    for task in sortedTasks.dropFirst() {
                        if var item = schedules[profileName]?[task.taskID] {
                            item.time = now.addingTimeInterval(self.minimumExecutionInterval)
                            schedules[profileName]?[task.taskID] = item
                            Logger.process.info("GlobalTimer: Rescheduled additional task \(task.taskID) for profile '\(profileName)' to maintain per-profile spacing")
                        }
                    }
                } else {
                    // Schedule subsequent profiles with 5-minute delays
                    let delayMinutes = index * 5
                    let executeTime = now.addingTimeInterval(TimeInterval(delayMinutes * 60))
                    
                    // Get the earliest task for this profile
                    let firstTask = sortedTasks.first!
                    if var item = schedules[profileName]?[firstTask.taskID] {
                        item.time = executeTime
                        schedules[profileName]?[firstTask.taskID] = item
                        Logger.process.info("GlobalTimer: Scheduled profile '\(profileName)' to execute in \(delayMinutes) minutes")
                    }
                    
                    // Reschedule other tasks for this profile to 5 minutes after the first
                    for task in sortedTasks.dropFirst() {
                        if var item = schedules[profileName]?[task.taskID] {
                            item.time = executeTime.addingTimeInterval(self.minimumExecutionInterval)
                            schedules[profileName]?[task.taskID] = item
                            Logger.process.info("GlobalTimer: Rescheduled additional task \(task.taskID) for profile '\(profileName)'")
                        }
                    }
                }
            }
        }
        
        // Clean up old execution times periodically
        cleanupOldExecutionTimes()
        
        scheduleNextTimer()
    }

    private func executeSchedule(profileName: String, taskID: UUID) {
        guard let item = schedules[profileName]?[taskID] else { return }
        
        // Remove the task from schedules
        schedules[profileName]?.removeValue(forKey: taskID)
        
        // Remove profile entry if no more tasks
        if schedules[profileName]?.isEmpty == true {
            schedules.removeValue(forKey: profileName)
        }
        
        // Record the execution time for the profile
        lastExecutionTime[profileName] = Date.now
        
        Logger.process.info("GlobalTimer: Executing task \(taskID) for profile '\(profileName)'")
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

        guard let (profileName, item) = schedules.min(by: { $0.value.time < $1.value.time }) else {
            Logger.process.info("GlobalTimer: No schedules")
            return
        }

        let interval = item.time.timeIntervalSince(.now)

        // Execute immediately if already due
        if interval <= 0 {
            Logger.process.info("GlobalTimer: Schedule '\(profileName)' already due, executing now")
            executeSchedule(profileName: profileName)
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

    private func executeSchedule(profileName: String) {
        guard let item = schedules.removeValue(forKey: profileName) else { return }
        
        // Record the execution time
        lastExecutionTime[profileName] = Date.now
        
        Logger.process.info("GlobalTimer: Executing schedule for '\(profileName)'")
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
        Logger.process.info("GlobalTimer: System woke, checking schedules")
        checkSchedules()
    }

    // MARK: - Helpers

    private func defaultTolerance(for interval: TimeInterval) -> TimeInterval {
        min(60, max(1, interval * 0.1))
    }
}
