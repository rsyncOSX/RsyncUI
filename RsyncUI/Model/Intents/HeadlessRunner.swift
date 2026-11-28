//
//  HeadlessRunner.swift
//  RsyncUI
//
//  Estimate and execute tasks without any view. Used by App Intents
//  (Shortcuts, Spotlight, Siri and `shortcuts run`).
//

import AppKit
import Foundation
import OSLog

/// Summary of one task after an estimate or an execute.
struct HeadlessTaskResult: Sendable {
    var displayName: String {
        backupID.isEmpty ? "#\(hiddenID)" : backupID
    }


    let hiddenID: Int
    let backupID: String
    let datatosynchronize: Bool
    let filestransferred: Int
    let newfiles: Int
    let deletefiles: Int
    let transferredbytes: Int
    let stats: String?
    /// The estimate looks suspicious, for example every file is new.
    let confirmexecute: Bool
}

enum HeadlessRunnerError: LocalizedError {
    case busy
    case noRsync
    case profileNotFound(String)
    case noConfigurations(String)
    case taskNotFound(Int)
    case estimateFailed(String?)
    case executeFailed(String?)
    case tooManyDeletions(Int)
    case needsConfirmation([String])
    case sourceMissingOrEmpty(String, String)
    case notAllowedInShortcuts([String])

    var errorDescription: String? {
        switch self {
        case .busy:
            String(localized: "RsyncUI is already running a task.")
        case .noRsync:
            String(localized: "No valid rsync was found.")
        case let .profileNotFound(name):
            String(localized: "The profile \(name) does not exist.")
        case let .noConfigurations(name):
            String(localized: "No tasks could be read from the profile \(name).")
        case let .taskNotFound(hiddenID):
            String(localized: "No task with ID \(hiddenID) in this profile.")
        case let .estimateFailed(message):
            String(localized: "The estimate failed. \(message ?? "")")
        case let .executeFailed(message):
            String(localized: "The synchronization failed. \(message ?? "")")
        case let .tooManyDeletions(count):
            String(localized: "The estimate shows \(count) files to delete, more than Maximum Deletions allows.")
        case let .needsConfirmation(names):
            String(localized: "The estimate for \(names.joined(separator: ", ")) needs confirmation. Open RsyncUI to review and synchronize.")
        case let .notAllowedInShortcuts(names):
            String(localized: "Not allowed in Shortcuts: \(names.joined(separator: ", ")). Verify these tasks in RsyncUI and allow them in Shortcuts.")
        case let .sourceMissingOrEmpty(name, path):
            String(localized: "The source of \(name) is missing or empty: \(path). Nothing was synchronized.")
        }
    }
}

@MainActor
enum HeadlessRunner {
    /// Name used for the default profile, which is stored as `nil`.
    static let defaultProfileName = "Default"

    private static var busy = false
    /// Strong references while a run is in progress.
    private static var activeEstimate: Estimate?
    private static var activeExecute: Execute?
    private static var quitTask: Task<Void, Never>?

    // MARK: Quit when launched only for an intent

    /// Shortcuts launches RsyncUI without a window to run an intent and leaves it
    /// running. Quit a few seconds after the last intent call if no window is open
    /// and nothing is running. Each call restarts the countdown, so a user picking
    /// a profile or task in Shortcuts keeps the app alive.
    static func scheduleQuitIfNoWindow() {
        quitTask?.cancel()
        quitTask = Task { @MainActor in
            try? await Task.sleep(for: .seconds(5))
            // Shortcuts launches RsyncUI as a background-only process: activation
            // policy .prohibited and the app reported as hidden. Only a normal
            // launch counts ⌘H-hidden as the user having RsyncUI open.
            let app = NSApplication.shared
            let launchedForIntent = app.activationPolicy() == .prohibited
            guard !Task.isCancelled,
                  !busy,
                  SharedReference.shared.process == nil,
                  !SharedReference.shared.executionFinalizationInProgress,
                  launchedForIntent || !app.isHidden,
                  // A visible or minimized window means the user opened RsyncUI.
                  !app.windows.contains(where: { $0.isVisible || $0.isMiniaturized })
            else { return }
            Logger.process.debugMessageOnly("HeadlessRunner: no window after intent, quitting")
            NSApplication.shared.terminate(nil)
        }
    }

    // MARK: Profiles and tasks

    static func profileNames() -> [String] {
        scheduleQuitIfNoWindow()
        return [defaultProfileName] + Homepath().getFullPathMacSerialCatalogsAsStringNames()
    }

    /// The stored profile value: `nil` is the default profile.
    static func storedProfile(_ name: String) -> String? {
        name.caseInsensitiveCompare(defaultProfileName) == .orderedSame ? nil : name
    }

    static func configurations(profile name: String) async throws -> [SynchronizeConfiguration] {
        defer { scheduleQuitIfNoWindow() }
        try await prepareEnvironment()
        let profile = storedProfile(name)
        if let profile, !Homepath().getFullPathMacSerialCatalogsAsStringNames().contains(profile) {
            throw HeadlessRunnerError.profileNotFound(name)
        }
        guard let configurations = await ReadSynchronizeConfigurationJSON()
            .readjsonfilesynchronizeconfigurations(profile, SharedReference.shared.rsyncversion3)
        else {
            throw HeadlessRunnerError.noConfigurations(name)
        }
        return configurations
    }

    // MARK: Estimate

    /// Dry run. Nothing is changed on disk.
    static func estimate(profile name: String, hiddenIDs: [Int]) async throws -> [HeadlessTaskResult] {
        let configurations = try await configurations(profile: name)
        let selected = try select(hiddenIDs, from: configurations)
        return try await withRunLock {
            try await runEstimate(profile: storedProfile(name), configurations: configurations, selected: selected)
        }
    }

    // MARK: Execute

    /// Only tasks the user has verified and allowed in RsyncUI may run.
    /// Estimates first, then synchronizes the tasks that have changes, following
    /// each task's own --delete setting like RsyncUI does. Stops before
    /// synchronizing if a source that --delete would mirror is missing or empty,
    /// if the estimate needs confirmation (the Confirm execute setting), or if
    /// deletions exceed the optional `maxDeletions`.
    static func execute(profile name: String,
                        hiddenIDs: [Int],
                        maxDeletions: Int?) async throws -> [HeadlessTaskResult] {
        let configurations = try await configurations(profile: name)
        let selected = try select(hiddenIDs, from: configurations)
        let profile = storedProfile(name)
        let torun = configurations.filter {
            $0.task != SharedReference.shared.halted && (selected.isEmpty || selected.contains($0.id))
        }
        // Every task must be verified and allowed in RsyncUI. Nothing runs if one is not.
        let notAllowed = torun.filter { !$0.isAllowedInShortcuts }
            .map { $0.backupID.isEmpty ? "#\($0.hiddenID)" : $0.backupID }
        guard notAllowed.isEmpty else { throw HeadlessRunnerError.notAllowedInShortcuts(notAllowed) }
        try checkSources(torun)

        return try await withRunLock {
            let estimated = try await runEstimate(profile: profile, configurations: configurations, selected: selected)
            if SharedReference.shared.confirmexecute {
                let suspicious = estimated.filter(\.confirmexecute).map(\.displayName)
                if !suspicious.isEmpty { throw HeadlessRunnerError.needsConfirmation(suspicious) }
            }
            let deletions = estimated.reduce(0) { $0 + $1.deletefiles }
            if let maxDeletions, deletions > maxDeletions {
                throw HeadlessRunnerError.tooManyDeletions(deletions)
            }
            let withData = Set(estimated.filter(\.datatosynchronize).map(\.hiddenID))
            guard !withData.isEmpty else { return estimated }

            let uuids = Set(configurations.filter { withData.contains($0.hiddenID) }.map(\.id))
            try await runExecute(profile: profile, configurations: configurations, selected: uuids)
            return estimated.filter(\.datatosynchronize)
        }
    }

    /// With --delete, an empty or missing local source (for example an external
    /// drive that is not mounted) would empty the destination. Pull tasks
    /// (syncremote) have a remote source and are not checked.
    private static func checkSources(_ configurations: [SynchronizeConfiguration]) throws {
        let fileManager = FileManager.default
        for config in configurations where config.task != "syncremote"
            && SynchronizeConfirmationView.usesDestinationDeletion(config) {
            let path = (config.localCatalog as NSString).expandingTildeInPath
            var isDirectory: ObjCBool = false
            let exists = fileManager.fileExists(atPath: path, isDirectory: &isDirectory)
            let contents = (try? fileManager.contentsOfDirectory(atPath: path)) ?? []
            let isEmpty = isDirectory.boolValue && contents.allSatisfy { $0 == ".DS_Store" }
            if !exists || isEmpty {
                let name = config.backupID.isEmpty ? "#\(config.hiddenID)" : config.backupID
                throw HeadlessRunnerError.sourceMissingOrEmpty(name, config.localCatalog)
            }
        }
    }

    // MARK: Internals

    private static func select(_ hiddenIDs: [Int],
                               from configurations: [SynchronizeConfiguration]) throws -> Set<UUID> {
        // Empty selection means all tasks, matching the app.
        guard !hiddenIDs.isEmpty else { return [] }
        return try Set(hiddenIDs.map { hiddenID in
            guard let config = configurations.first(where: { $0.hiddenID == hiddenID }) else {
                throw HeadlessRunnerError.taskNotFound(hiddenID)
            }
            return config.id
        })
    }

    /// One run at a time, and never while the app window is running a task.
    private static func withRunLock<T>(_ body: () async throws -> T) async throws -> T {
        guard !busy,
              SharedReference.shared.process == nil,
              !SharedReference.shared.executionFinalizationInProgress
        else { throw HeadlessRunnerError.busy }
        busy = true
        defer {
            busy = false
            scheduleQuitIfNoWindow()
        }
        return try await body()
    }

    /// The app window normally loads settings and the rsync version at launch.
    /// When the system launches RsyncUI only to run an intent, do it here.
    private static func prepareEnvironment() async throws {
        if SharedReference.shared.errorobject == nil {
            SharedReference.shared.errorobject = AlertError()
        }
        if SharedReference.shared.rsyncversionshort == nil {
            await ReadUserConfigurationJSON().readuserconfiguration()
            let version = Rsyncversion()
            version.getRsyncVersion()
            // Wait up to 5 seconds for `rsync --version` to report.
            for _ in 0 ..< 50 where SharedReference.shared.rsyncversionshort == nil {
                try await Task.sleep(for: .milliseconds(100))
            }
        }
        guard SharedReference.shared.norsync == false else { throw HeadlessRunnerError.noRsync }
    }

    private static func takeErrorMessage() -> String? {
        let error = SharedReference.shared.errorobject?.activeError
        SharedReference.shared.errorobject?.activeError = nil
        return error?.localizedDescription
    }

    private static func runEstimate(profile: String?,
                                    configurations: [SynchronizeConfiguration],
                                    selected: Set<UUID>) async throws -> [HeadlessTaskResult] {
        let progress = ProgressDetails()
        progress.startEstimation()
        let complete = await withCheckedContinuation { continuation in
            activeEstimate = Estimate.start(profile: profile,
                                            configurations: configurations,
                                            selecteduuids: selected,
                                            progressdetails: progress) { complete in
                continuation.resume(returning: complete)
            }
        }
        activeEstimate = nil
        guard complete else { throw HeadlessRunnerError.estimateFailed(takeErrorMessage()) }

        return (progress.estimatedlist ?? []).map { record in
            HeadlessTaskResult(hiddenID: record.hiddenID,
                               backupID: record.backupID,
                               datatosynchronize: record.datatosynchronize,
                               filestransferred: record.filestransferredInt,
                               newfiles: record.newfilesInt,
                               deletefiles: record.deletefilesInt,
                               transferredbytes: record.totaltransferredfilessizeInt,
                               stats: record.stats,
                               confirmexecute: record.confirmexecute)
        }
    }

    private static func runExecute(profile: String?,
                                   configurations: [SynchronizeConfiguration],
                                   selected: Set<UUID>) async throws {
        let outcome = await withCheckedContinuation { continuation in
            activeExecute = Execute.start(profile: profile,
                                          configurations: configurations,
                                          selecteduuids: selected,
                                          noestprogressdetails: nil,
                                          fileHandler: { _ in },
                                          updateconfigurations: { _, outcome in
                                              continuation.resume(returning: outcome)
                                          })
        }
        activeExecute = nil
        guard outcome == .success else { throw HeadlessRunnerError.executeFailed(takeErrorMessage()) }
        Logger.process.debugMessageOnly("HeadlessRunner: execution completed")
    }
}
