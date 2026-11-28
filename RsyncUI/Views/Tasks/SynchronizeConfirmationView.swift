import SwiftUI

struct SynchronizeConfirmationView: View {
    let configurations: [SynchronizeConfiguration]
    let incompletePreview: Bool
    /// Tasks with a complete estimate and changes to synchronize
    let estimatedIDs: Set<UUID>
    let cancel: () -> Void
    let preview: () -> Void
    let synchronize: () -> Void
    let synchronizeEstimated: () -> Void

    /// Also used by App Intents before an unattended run.
    static func usesDestinationDeletion(_ configuration: SynchronizeConfiguration) -> Bool {
        let builder = ArgumentsSynchronize(config: configuration)
        let arguments = builder.argumentsSynchronize(dryRun: false, forDisplay: false) ?? []
        let deletionOptions: Set<String> = [
            "--delete", "--del", "--delete-before", "--delete-during", "--delete-delay",
            "--delete-after", "--delete-excluded", "--delete-missing-args"
        ]
        return arguments.prefix { $0 != "--" }.contains { deletionOptions.contains($0) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Confirm Synchronization", systemImage: "exclamationmark.triangle")
                .font(.title2.weight(.semibold))
                .accessibilityAddTraits(.isHeader)

            if incompletePreview {
                Text("The estimate could not determine all changes. Estimate again, or synchronize these tasks with the changes still unknown.")
            } else {
                Text("Estimate the changes first, or synchronize immediately.")
            }

            if configurations.contains(where: Self.usesDestinationDeletion) {
                Label("File deletion is enabled. Synchronization may remove files from the destination.",
                      systemImage: "trash")
                    .padding(12)
                    .background(.red.opacity(0.10), in: RoundedRectangle(cornerRadius: 8))
            }

            if configurations.count == 1, let configuration = configurations.first {
                ScrollView {
                    SelectedTaskRouteView(configuration: configuration)
                }
                .frame(maxHeight: 145)
            } else {
                Text("Tasks to synchronize: \(configurations.count)")
                    .font(.headline)
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 6) {
                        ForEach(configurations) { configuration in
                            Text(configuration.backupID.isEmpty ? configuration.localCatalog : configuration.backupID)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(maxHeight: 120)
            }

            if incompletePreview, !estimatedIDs.isEmpty {
                HStack {
                    Text("Estimated tasks with changes: \(estimatedIDs.count)")
                        .help(configurations.filter { estimatedIDs.contains($0.id) }
                            .map { $0.backupID.isEmpty ? $0.localCatalog : $0.backupID }
                            .joined(separator: "\n"))
                    Spacer()
                    Button("Synchronize Estimated Tasks", action: synchronizeEstimated)
                }
            }

            Divider()
            HStack {
                Button("Cancel", action: cancel)
                    .keyboardShortcut(.cancelAction)
                Spacer()
                Button("Synchronize Now", action: synchronize)
                    .disabled(configurations.isEmpty)
                Button("Estimate (Dry Run)", action: preview)
                    .buttonStyle(.borderedProminent)
                    .keyboardShortcut(.defaultAction)
                    .disabled(configurations.isEmpty)
            }
        }
        .padding(24)
        .frame(width: 490)
    }
}
