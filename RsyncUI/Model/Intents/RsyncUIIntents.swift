//
//  RsyncUIIntents.swift
//  RsyncUI
//
//  App Intents for Shortcuts, Spotlight and Siri. All intents run without
//  opening the RsyncUI window.
//

import AppIntents
import Foundation

// MARK: - Entities

struct ProfileEntity: AppEntity {
    static let typeDisplayRepresentation: TypeDisplayRepresentation = "Profile"
    static let defaultQuery = ProfileQuery()

    let id: String

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(id)")
    }
}

struct ProfileQuery: EntityQuery {
    @MainActor
    func entities(for identifiers: [String]) async throws -> [ProfileEntity] {
        let names = HeadlessRunner.profileNames()
        return identifiers.filter(names.contains).map(ProfileEntity.init)
    }

    @MainActor
    func suggestedEntities() async throws -> [ProfileEntity] {
        HeadlessRunner.profileNames().map(ProfileEntity.init)
    }
}

/// A task is identified by profile and hiddenID. The UUID in
/// `SynchronizeConfiguration` is regenerated on every read, so it cannot be used.
struct TaskEntity: AppEntity {
    static let typeDisplayRepresentation: TypeDisplayRepresentation = "Task"
    static let defaultQuery = TaskQuery()

    let id: String
    let profile: String
    let hiddenID: Int
    let backupID: String
    let summary: String

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(backupID.isEmpty ? summary : backupID)",
                              subtitle: "\(profile) · \(summary)")
    }

    init(profile: String, config: SynchronizeConfiguration) {
        self.profile = profile
        hiddenID = config.hiddenID
        backupID = config.backupID
        let destination = config.offsiteServer.isEmpty
            ? config.offsiteCatalog
            : "\(config.offsiteServer):\(config.offsiteCatalog)"
        summary = "\(config.localCatalog) → \(destination)"
        id = "\(profile)#\(config.hiddenID)"
    }
}

struct TaskQuery: EntityQuery {
    @IntentParameterDependency<RunTaskIntent>(\.$profile) var runProfile
    @IntentParameterDependency<EstimateTaskIntent>(\.$profile) var estimateProfile

    @MainActor
    func entities(for identifiers: [String]) async throws -> [TaskEntity] {
        var result = [TaskEntity]()
        let byProfile = Dictionary(grouping: identifiers) { $0.split(separator: "#").first.map(String.init) ?? "" }
        for (profile, ids) in byProfile {
            let tasks = try await Self.tasks(in: profile)
            result += tasks.filter { ids.contains($0.id) }
        }
        return result
    }

    @MainActor
    func suggestedEntities() async throws -> [TaskEntity] {
        // Synchronize Tasks only offers tasks allowed in Shortcuts
        if let profile = runProfile?.profile.id {
            return try await Self.tasks(in: profile, allowedOnly: true)
        }
        if let profile = estimateProfile?.profile.id {
            return try await Self.tasks(in: profile)
        }
        var result = [TaskEntity]()
        for profile in HeadlessRunner.profileNames() {
            result += (try? await Self.tasks(in: profile)) ?? []
        }
        return result
    }

    @MainActor
    static func tasks(in profile: String, allowedOnly: Bool = false) async throws -> [TaskEntity] {
        try await HeadlessRunner.configurations(profile: profile)
            .filter { $0.task != SharedReference.shared.halted && (!allowedOnly || $0.isAllowedInShortcuts) }
            .map { TaskEntity(profile: profile, config: $0) }
    }
}

// MARK: - Helpers

/// Writes "0 KB" instead of "Zero KB".
private func formattedSize(_ bytes: Int) -> String {
    let formatter = ByteCountFormatter()
    formatter.countStyle = .file
    formatter.allowsNonnumericFormatting = false
    return formatter.string(fromByteCount: Int64(bytes))
}

private extension [HeadlessTaskResult] {
    /// Each task is a full sentence, because Shortcuts may show the dialog
    /// without line breaks.
    var dialogText: String {
        guard !isEmpty else { return String(localized: "Nothing to synchronize.") }
        return map { result in
            let name = result.displayName
            guard result.datatosynchronize else {
                return String(localized: "\(name): up to date.")
            }
            let files = result.filestransferred == 1
                ? String(localized: "1 file")
                : String(localized: "\(result.filestransferred) files")
            let size = formattedSize(result.transferredbytes)
            return String(localized: "\(name): \(files), \(size), \(result.deletefiles) to delete.")
        }.joined(separator: "\n")
    }

    var anyDataToSynchronize: Bool {
        contains(where: \.datatosynchronize)
    }
}

private func hiddenIDs(_ tasks: [TaskEntity]?, profile: ProfileEntity) throws -> [Int] {
    guard let tasks, !tasks.isEmpty else { return [] }
    let wrong = tasks.filter { $0.profile != profile.id }
    guard wrong.isEmpty else {
        throw HeadlessRunnerError.profileNotFound(wrong[0].profile)
    }
    return tasks.map(\.hiddenID)
}

// MARK: - Intents

struct EstimateTaskIntent: AppIntent {
    static let title: LocalizedStringResource = "Estimate Tasks"
    static let description = IntentDescription(
        "Runs rsync as a dry run and reports what would be synchronized. Nothing is changed."
    )
    static let openAppWhenRun = false

    @Parameter(title: "Profile")
    var profile: ProfileEntity

    @Parameter(title: "Tasks", description: "Leave empty to estimate all tasks in the profile.")
    var tasks: [TaskEntity]?

    static var parameterSummary: some ParameterSummary {
        Summary("Estimate \(\.$tasks) in \(\.$profile)")
    }

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<Bool> & ProvidesDialog {
        let results = try await HeadlessRunner.estimate(profile: profile.id,
                                                        hiddenIDs: hiddenIDs(tasks, profile: profile))
        return .result(value: results.anyDataToSynchronize, dialog: "\(results.dialogText)")
    }
}

struct RunTaskIntent: AppIntent {
    static let title: LocalizedStringResource = "Synchronize Tasks"
    static let description = IntentDescription(
        "Synchronizes tasks you have verified and allowed in RsyncUI. Estimates first, then synchronizes the tasks that have changes, following each task's --delete setting. Stops if a source is missing or empty, or if the estimate needs confirmation."
    )
    static let openAppWhenRun = false

    @Parameter(title: "Profile")
    var profile: ProfileEntity

    @Parameter(title: "Tasks", description: "Leave empty to synchronize all tasks in the profile.")
    var tasks: [TaskEntity]?

    @Parameter(title: "Maximum Deletions",
               description: "Optional. Stop if the estimate shows more files to delete than this. Leave empty to follow the task.")
    var maxDeletions: Int?

    static var parameterSummary: some ParameterSummary {
        Summary("Synchronize \(\.$tasks) in \(\.$profile)") {
            \.$maxDeletions
        }
    }

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let results = try await HeadlessRunner.execute(profile: profile.id,
                                                       hiddenIDs: hiddenIDs(tasks, profile: profile),
                                                       maxDeletions: maxDeletions)
        return .result(dialog: "\(results.dialogText)")
    }
}

// MARK: - Shortcuts provider

struct RsyncUIShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(intent: EstimateTaskIntent(),
                    phrases: ["Estimate \(\.$profile) in \(.applicationName)"],
                    shortTitle: "Estimate",
                    systemImageName: "magnifyingglass")
        AppShortcut(intent: RunTaskIntent(),
                    phrases: ["Synchronize \(\.$profile) with \(.applicationName)"],
                    shortTitle: "Synchronize",
                    systemImageName: "arrow.triangle.2.circlepath")
    }
}
