//
//  DestinationDeletion.swift
//  RsyncUI
//

import Foundation

/// True when the rsync arguments of a task delete files in the destination.
/// In RsyncUI-next this check is `SynchronizeConfirmationView.usesDestinationDeletion`.
@MainActor
enum DestinationDeletion {
    static func isEnabled(_ configuration: SynchronizeConfiguration) -> Bool {
        let builder = ArgumentsSynchronize(config: configuration)
        let arguments = builder.argumentsSynchronize(dryRun: false, forDisplay: false) ?? []
        let deletionOptions: Set<String> = [
            "--delete", "--del", "--delete-before", "--delete-during", "--delete-delay",
            "--delete-after", "--delete-excluded", "--delete-missing-args"
        ]
        return arguments.prefix { $0 != "--" }.contains { deletionOptions.contains($0) }
    }
}
