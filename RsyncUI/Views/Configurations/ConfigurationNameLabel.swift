//
//  ConfigurationNameLabel.swift
//  RsyncUI
//

import SwiftUI

/// Task name, with an icon if the task deletes files at the destination.
struct ConfigurationNameLabel: View {
    @Environment(\.backgroundProminence) private var backgroundProminence

    let configuration: SynchronizeConfiguration

    var body: some View {
        HStack(spacing: 4) {
            if configuration.parameter4?.isEmpty == false {
                Image(systemName: "trash")
                    .font(.caption)
                    .foregroundStyle(backgroundProminence == .increased ? Color.primary : Color.red)
                    .help("Deletes destination items missing from the source")
                    .accessibilityLabel("Deletes destination items missing from the source")
            }
            Text(configuration.backupID.isEmpty ? String(localized: "No ID set") : configuration.backupID)
                .lineLimit(1)
                .help(configuration.backupID)
            if configuration.isAllowedInShortcuts {
                Image(systemName: "checkmark.circle.fill")
                    .font(.caption)
                    .foregroundStyle(backgroundProminence == .increased ? Color.primary : Color.green)
                    .help("Allowed in Shortcuts")
                    .accessibilityLabel("Allowed in Shortcuts")
            }
        }
    }
}
