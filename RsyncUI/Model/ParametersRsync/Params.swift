//
//  Params.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 20/11/2025.
//

import Foundation
import RsyncArguments

@MainActor
struct Params {
    func params(
        config: SynchronizeConfiguration) -> Parameters {
        var rsyncdaemon = false
        var deleteExtraneous = false
        if config.rsyncdaemon == 1 { rsyncdaemon = true }
        if config.parameter4 != nil { deleteExtraneous = true }
        return Parameters(
            task: config.task,
            basicParameters: BasicRsyncParameters(
                archiveMode: DefaultRsyncParameters.archiveMode.rawValue,
                verboseOutput: DefaultRsyncParameters.verboseOutput.rawValue,
                compressionEnabled: DefaultRsyncParameters.compressionEnabled.rawValue,
                deleteExtraneous: deleteExtraneous ? DefaultRsyncParameters.deleteExtraneous.rawValue : ""
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
                offsiteCatalog: config.offsiteCatalog,
                sharedPathForRestore: SharedReference.shared.pathforrestore ?? ""
            ),
            snapshotNumber: config.snapshotnum,
            isRsyncDaemon: rsyncdaemon, // Use Bool instead of -1/1
            rsyncVersion3: SharedReference.shared.rsyncversion3
        )
    }
}
