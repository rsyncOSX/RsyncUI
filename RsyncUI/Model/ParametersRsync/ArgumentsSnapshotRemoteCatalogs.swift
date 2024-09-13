//
//  ArgumentsSnapshotRemoteCatalogs.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 27/08/2024.
//

// swiftlint:disable line_length

import Foundation
import OSLog
import RsyncArguments

@MainActor
final class ArgumentsSnapshotRemoteCatalogs {
    var config: SynchronizeConfiguration?

    func remotefilelistarguments() -> [String]? {
        if let config {
            Logger.process.info("RemoteFileListArguments: using RsyncParametersRestore() from RsyncArguments")
            let rsyncparametersrestore =
                RsyncParametersRestore(task: config.task,
                                       parameter1: config.parameter1,
                                       parameter2: config.parameter2,
                                       parameter3: config.parameter3,
                                       parameter4: config.parameter4,
                                       parameter8: config.parameter8,
                                       parameter9: config.parameter9,
                                       parameter10: config.parameter10,
                                       parameter11: config.parameter11,
                                       parameter12: config.parameter12,
                                       parameter13: config.parameter13,
                                       parameter14: config.parameter14,
                                       sshport: String(config.sshport ?? -1),
                                       sshkeypathandidentityfile: config.sshkeypathandidentityfile ?? "",
                                       sharedsshport: String(SharedReference.shared.sshport ?? -1),
                                       sharedsshkeypathandidentityfile: SharedReference.shared.sshkeypathandidentityfile,
                                       localCatalog: config.localCatalog,
                                       offsiteCatalog: config.offsiteCatalog,
                                       offsiteServer: config.offsiteServer,
                                       offsiteUsername: config.offsiteUsername,
                                       sharedpathforrestore: SharedReference.shared.pathforrestore ?? "",
                                       snapshotnum: config.snapshotnum ?? -1,
                                       rsyncdaemon: config.rsyncdaemon ?? -1,
                                       rsyncversion3: SharedReference.shared.rsyncversion3)
            rsyncparametersrestore.remoteargumentssnapshotcataloglist()
            return rsyncparametersrestore.computedarguments
        }
        return nil
    }

    init(config: SynchronizeConfiguration) {
        guard config.task == SharedReference.shared.snapshot else { return }
        self.config = config
    }
}

// swiftlint:enable line_length
