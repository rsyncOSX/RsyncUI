//
//  HiddenConfigurations.swift
//  RsyncUI
//

import Foundation

/// Snapshot and syncremote tasks require rsync 3.x. When RsyncUI runs with
/// openrsync they are left out of the loaded list, but they still exist on disk.
/// They are kept here per profile so that writing the visible list never
/// deletes them, and so that new tasks never reuse their hiddenIDs.
@MainActor
enum HiddenConfigurations {
    private static var store: [String: [SynchronizeConfiguration]] = [:]

    private static func key(_ profile: String?) -> String {
        // A profile name is a folder name and never contains NUL.
        profile ?? "\u{0}default"
    }

    static func set(_ hidden: [SynchronizeConfiguration], profile: String?) {
        store[key(profile)] = hidden.isEmpty ? nil : hidden
    }

    static func hidden(profile: String?) -> [SynchronizeConfiguration] {
        store[key(profile)] ?? []
    }

    static func hiddenIDs(profile: String?) -> Set<Int> {
        Set(hidden(profile: profile).map(\.hiddenID))
    }

    /// Tasks requiring rsync 3.x are hidden when running with openrsync.
    static func isHidden(task: String, rsyncversion3: Bool) -> Bool {
        !rsyncversion3 && (task == SharedReference.shared.snapshot || task == SharedReference.shared.syncremote)
    }

    /// The list to persist: the visible list plus every hidden task it does not
    /// already contain, in their original order after the visible ones.
    static func merge(_ visible: [SynchronizeConfiguration],
                      hidden: [SynchronizeConfiguration]) -> [SynchronizeConfiguration] {
        let visibleIDs = Set(visible.map(\.hiddenID))
        return visible + hidden.filter { !visibleIDs.contains($0.hiddenID) }
    }
}
