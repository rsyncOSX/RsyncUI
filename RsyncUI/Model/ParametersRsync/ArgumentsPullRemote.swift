//
//  ArgumentsPullRemote.swift
//  RsyncOSX
//
//  Created by Thomas Evensen on 13/10/2019.
//  Copyright © 2019 Thomas Evensen. All rights reserved.
//
// swiftlint:disable line_length

import Foundation
import RsyncArguments

@MainActor
final class ArgumentsPullRemote {
    var config: SynchronizeConfiguration?

    func argumentspullremotewithparameters(dryRun: Bool, forDisplay: Bool, keepdelete: Bool) -> [String]? {
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
            let rsyncparameterssynchronize = RsyncParametersPullRemote(parameters: params)
            do {
                try rsyncparameterssynchronize.argumentsPullRemoteWithParameters(forDisplay: forDisplay,
                                                                                 verify: false,
                                                                                 dryrun: dryRun, keepDelete: keepdelete)
                return rsyncparameterssynchronize.computedArguments
            } catch {
                return nil
            }
        }
        return nil
    }

    init(config: SynchronizeConfiguration?) {
        self.config = config
    }
}

// swiftlint:enable line_length
