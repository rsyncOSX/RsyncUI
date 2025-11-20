//
//  ArgumentsSnapshotRemoteCatalogs.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 27/08/2024.
//

// swiftlint:disable line_length

import Foundation
import RsyncArguments

@MainActor
final class ArgumentsSnapshotRemoteCatalogs {
    var config: SynchronizeConfiguration?

    func remotefilelistarguments() -> [String]? {
        if let config {
            let params = Parameters(
                task: config.task,
                basicParameters: BasicRsyncParameters(
                    archiveMode: "--archive",
                    verboseOutput: "--verbose",
                    compressionEnabled: "--compress",
                    deleteExtraneous: "--delete"
                ),
                optionalParameters: OptionalRsyncParameters(parameter8: config.parameter8,
                                                            parameter9: config.parameter9,
                                                            parameter10: config.parameter10,
                                                            parameter11: config.parameter11,
                                                            parameter12: config.parameter12,
                                                            parameter13: config.parameter13,
                                                            parameter14: config.parameter14),

                sshParameters: SSHParameters(
                    offsiteServer: config.offsiteServer,
                    offsiteUsername: config.offsiteUsername,
                    sshport: String(config.sshport ?? -1),
                    sshkeypathandidentityfile: config.sshkeypathandidentityfile ?? "",
                    sharedsshport: String(SharedReference.shared.sshport ?? -1),
                    sharedsshkeypathandidentityfile: SharedReference.shared.sshkeypathandidentityfile,
                    rsyncversion3: SharedReference.shared.rsyncversion3
                ),
                paths: PathConfiguration(
                    localCatalog: config.localCatalog,
                    offsiteCatalog: config.offsiteCatalog
                ),
                snapshotNumber: config.snapshotnum,
                isRsyncDaemon: false, // Use Bool instead of -1/1
                rsyncVersion3: SharedReference.shared.rsyncversion3
            )
            let rsyncparametersrestore = RsyncParametersRestore(parameters: params)
            do {
                try rsyncparametersrestore.remoteArgumentsSnapshotCatalogList()
                return rsyncparametersrestore.computedArguments
            } catch {
                return nil
            }
        }
        return nil
    }

    init(config: SynchronizeConfiguration) {
        guard config.task == SharedReference.shared.snapshot else { return }
        self.config = config
    }
}

// swiftlint:enable line_length
