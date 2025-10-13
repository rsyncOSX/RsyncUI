import AppKit
import Foundation
import Observation
import OSLog

/// A singleton timer manager that schedules and executes tasks at specific times.
/// Uses both NSBackgroundActivityScheduler (for background execution) and Timer (for foreground execution).
/// Automatically handles system wake events to check for missed schedules.
@Observable
@MainActor
final class GlobalTimer {
    
    static let shared = GlobalTimer()

    // MARK: - Properties

    /// Active foreground timer that checks schedules every 60 seconds
    var timer: Timer?
    /// On Wake in orogress
    var onwake: Bool = false
    /// Currently active schedule identifier
    @ObservationIgnored var schedule: String?
    /// Dictionary of scheduled tasks with their execution times and callbacks
    private var timerschedules: [String: (time: Date, callback: () -> Void)] = [:]
    /// Dictionary of background schedulers for each profile
    private var NSbackgroundbackgroundschedules: [String: NSBackgroundActivityScheduler] = [:]
    /// Observer for system wake notifications
    private var wakeObserver: NSObjectProtocol?
    // MARK: - Initialization

    private init() {
        setupWakeNotification()
    }

    // MARK: - Public Methods

    /// Schedules a task to execute at a specific time for a given profile.
    /// Creates both a background scheduler and starts a foreground timer as backup.
    ///
    /// - Parameters:
    ///   - profile: The profile name for this schedule. Uses "Default" if nil.
    ///   - time: The date and time when the task should execute.
    ///   - callback: The closure to execute when the scheduled time arrives.
    func addSchedule(profile: String?, time: Date, callback: @escaping () -> Void) {
        let profileName = profile ?? "Default"
        Logger.process.info("GlobalTimer: Adding schedule for profile '\(profileName)' at \(time)")

        // Cancel any existing scheduler for this profile
        if let existingScheduler = NSbackgroundbackgroundschedules[profileName] {
            existingScheduler.invalidate()
            Logger.process.info("GlobalTimer: Cancelled existing scheduler for '\(profileName)'")
        }

        // Store the schedule
        timerschedules[profileName] = (time, callback)

        // Create and configure background scheduler
        let NSbackgroundscheduler = NSBackgroundActivityScheduler(identifier: "no.blogspot.RsyncUI.\(profileName)")
        let interval = time.timeIntervalSince(Date.now)

        if interval > 0 {
            NSbackgroundscheduler.interval = interval
            NSbackgroundscheduler.repeats = false
            NSbackgroundscheduler.qualityOfService = .userInitiated
            NSbackgroundscheduler.tolerance = 60 // Allow system to optimize execution within 60 seconds

            NSbackgroundscheduler.schedule { completion in
                Task { @MainActor in
                    Logger.process.info("GlobalTimer: Background scheduler fired for '\(profileName)'")
                    self.executeScheduleIfCurrent(profileName: profileName, scheduledTime: time)
                    completion(.finished)
                }
            }

            Logger.process.info("GlobalTimer: Background scheduler configured for '\(profileName)'")
            NSbackgroundbackgroundschedules[profileName] = NSbackgroundscheduler
            
        } else {
            Logger.process.warning("GlobalTimer: Scheduled time for '\(profileName)' is in the past, skipping")
        }

        // Start foreground timer as backup for when app is active
        startForegroundTimer()
    }

    /// Clears all scheduled tasks and invalidates all timers.
    func clearSchedules() {
        guard !timerschedules.isEmpty else {
            Logger.process.info("GlobalTimer: No schedules to clear")
            timer?.invalidate()
            timer = nil
            return
        }

        Logger.process.info("GlobalTimer: Clearing all schedules and timers")

        // Invalidate all background schedulers
        for (profileName, scheduler) in NSbackgroundbackgroundschedules {
            scheduler.invalidate()
            Logger.process.info("GlobalTimer: Invalidated background scheduler for '\(profileName)'")
        }

        // Clear all data structures
        NSbackgroundbackgroundschedules.removeAll()
        timerschedules.removeAll()

        // Stop foreground timer
        timer?.invalidate()
        timer = nil

        Logger.process.info("GlobalTimer: All schedules cleared")
    }

    /// Cleans up observers and resources. Call when app terminates if needed.
    func cleanup() {
        if let observer = wakeObserver {
            Logger.process.info("GlobalTimer: Removing wake notification observer")
            NSWorkspace.shared.notificationCenter.removeObserver(observer)
            wakeObserver = nil
        }
    }

    // MARK: - Private Methods

    /// Starts the foreground timer if not already running.
    /// The timer checks schedules every 60 seconds.
    private func startForegroundTimer() {
        guard timer == nil else { return }

        Logger.process.info("GlobalTimer: Starting foreground timer")
        timer = Timer.scheduledTimer(
            timeInterval: 60.0,
            target: self,
            selector: #selector(checkSchedules),
            userInfo: nil,
            repeats: true
        )
    }

    /// Checks all schedules and executes any that are due.
    /// Called by the foreground timer and wake notification.
    @objc private func checkSchedules() {
        let now = Date.now
        var firedSchedules: [String] = []

        // Check each schedule to see if it should fire
        for (profileName, schedule) in timerschedules {
            Logger.process.info("GlobalTimer: Checking schedule for '\(profileName)' - now: \(now), scheduled: \(schedule.time)")

            if now >= schedule.time {
                Logger.process.info("GlobalTimer: Executing schedule for '\(profileName)'")
                schedule.callback()
                firedSchedules.append(profileName)
            }
        }

        // Clean up executed schedules
        for profileName in firedSchedules {
            timerschedules.removeValue(forKey: profileName)
            NSbackgroundbackgroundschedules[profileName]?.invalidate()
            NSbackgroundbackgroundschedules.removeValue(forKey: profileName)
            Logger.process.info("GlobalTimer: Removed executed schedule for '\(profileName)'")
        }

        // Stop timer and cleanup if no more schedules
        if timerschedules.isEmpty {
            Logger.process.info("GlobalTimer: No more schedules, stopping timer")
            timer?.invalidate()
            timer = nil
            cleanup()
        }
    }

    /// Executes a schedule if it's still current (not replaced by a newer schedule).
    ///
    /// - Parameters:
    ///   - profileName: The profile identifier.
    ///   - scheduledTime: The original scheduled time to verify this execution is still valid.
    private func executeScheduleIfCurrent(profileName: String, scheduledTime: Date) {
        guard let schedule = timerschedules[profileName] else {
            Logger.process.info("GlobalTimer: No schedule found for '\(profileName)'")
            return
        }

        // Only execute if this is still the current scheduled time (not replaced)
        guard schedule.time == scheduledTime, Date.now >= schedule.time else {
            Logger.process.info("GlobalTimer: Skipping stale schedule for '\(profileName)'")
            return
        }

        Logger.process.info("GlobalTimer: Executing callback for '\(profileName)'")
        schedule.callback()

        // Clean up after execution
        timerschedules.removeValue(forKey: profileName)
        NSbackgroundbackgroundschedules.removeValue(forKey: profileName)
    }

    /// Sets up notification observer for system wake events.
    /// When the system wakes, it checks if any schedules were missed.
    private func setupWakeNotification() {
        wakeObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didWakeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor in
                onwake = true
                Logger.process.info("GlobalTimer: System woke up, checking for missed schedules in 3 seconds...")
                try await Task.sleep(seconds: 3)
                onwake = false
                checkSchedules()
            }
        }
    }
}
