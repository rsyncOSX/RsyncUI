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

    

    // Add these properties to your class
    

    private func checkSchedules() {
        let now = Date.now
        let dueProfiles = schedules.filter { now >= $0.value.time }.map(\.key)
        
        guard !dueProfiles.isEmpty else { return }
        
        // Group due profiles by their last execution time
        var eligibleProfiles: [String] = []
        var throttledProfiles: [String] = []
        
        for profileName in dueProfiles {
            if let lastExecution = self.lastExecutionTime[profileName] {
                let timeSinceLastExecution = now.timeIntervalSince(lastExecution)
                if timeSinceLastExecution < self.minimumExecutionInterval {
                    throttledProfiles.append(profileName)
                    Logger.process.debug("GlobalTimer: Throttling '\(profileName)' - executed \(Int(timeSinceLastExecution))s ago, need \(Int(self.minimumExecutionInterval))s")
                } else {
                    eligibleProfiles.append(profileName)
                }
            } else {
                // Never executed before, so it's eligible
                eligibleProfiles.append(profileName)
            }
        }
        
        // Handle throttled profiles - reschedule them for minimum interval from their last execution
        for profileName in throttledProfiles {
            if var item = schedules[profileName],
               let lastExecution = self.lastExecutionTime[profileName] {
                let nextAllowedTime = lastExecution.addingTimeInterval(self.minimumExecutionInterval)
                
                // Only reschedule if the new time is in the future
                if nextAllowedTime > now {
                    item.time = nextAllowedTime
                    schedules[profileName] = item
                    Logger.process.debug("GlobalTimer: Rescheduled '\(profileName)' to \(nextAllowedTime)")
                }
            }
        }
        
        // Execute eligible profiles one at a time with proper spacing
        if !eligibleProfiles.isEmpty {
            // Sort by original schedule time to maintain order
            let sortedEligible = eligibleProfiles.sorted { profile1, profile2 in
                let time1 = schedules[profile1]?.time ?? now
                let time2 = schedules[profile2]?.time ?? now
                return time1 < time2
            }
            
            // Execute the first one immediately
            if let firstProfile = sortedEligible.first {
                executeSchedule(profileName: firstProfile)
                
                // Reschedule remaining eligible profiles with 5-minute spacing
                for (index, profileName) in sortedEligible.dropFirst().enumerated() {
                    if var item = schedules[profileName] {
                        let delayMinutes = (index + 1) * 5
                        let newTime = now.addingTimeInterval(TimeInterval(delayMinutes * 60))
                        item.time = newTime
                        schedules[profileName] = item
                        Logger.process.info("GlobalTimer: Delayed '\(profileName)' by \(delayMinutes) minutes to maintain spacing")
                    }
                }
            }
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
        Logger.process.info("GlobalTimer: System woke, checking schedules")
        checkSchedules()
    }

    // MARK: - Helpers

    private func defaultTolerance(for interval: TimeInterval) -> TimeInterval {
        min(60, max(1, interval * 0.1))
    }
}
