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
        var sshport = ""
        var sshkeypathandidentityfile = ""
        var sharedsshport = ""
        var sharedsshkeypathandidentityfile = ""

        if config.rsyncdaemon == 1 { rsyncdaemon = true }
        if config.parameter4 != nil { deleteExtraneous = true }

        if let configsshport = config.sshport, configsshport != -1 {
            sshport = String(configsshport)
        }
        if let configurationsshcreatekey = config.sshkeypathandidentityfile {
            sshkeypathandidentityfile = configurationsshcreatekey
        }
        if let configsharedsshport = SharedReference.shared.sshport, configsharedsshport != -1 {
            sharedsshport = String(configsharedsshport)
        }
        if let configsharedsshcreatekey = SharedReference.shared.sshkeypathandidentityfile {
            sharedsshkeypathandidentityfile = configsharedsshcreatekey
        }

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
                sshport: String(sshport),
                sshkeypathandidentityfile: sshkeypathandidentityfile,
                sharedsshport: String(sharedsshport),
                sharedsshkeypathandidentityfile: sharedsshkeypathandidentityfile,
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
