//
//  ArgumentsRemoteFileList.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 07/08/2024.
//
// swiftlint:disable line_length

import Foundation
import OSLog
import RsyncArguments

enum Enumrestorefiles {
    case rsyncfilelistings
    case snapshotcatalogsonly
}

@MainActor
final class ArgumentsRemoteFileList {
    var config: SynchronizeConfiguration?
    var filelisttask: Enumrestorefiles

    func remotefilelistarguments() -> [String]? {
        if let config {
            Logger.process.info("RemoteFileListArguments: using RsyncParametersRestore() from RsyncArguments")
            let rsyncparametersrestore =
                RsyncParametersRestore(task: config.task,
                                       parameter1: config.parameter1,
                                       parameter2: config.parameter2,
                                       parameter3: config.parameter3,
                                       parameter4: config.parameter4,
                                       parameter5: config.parameter5,
                                       parameter6: config.parameter5,
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
            switch filelisttask {
            case .rsyncfilelistings:
                if config.task == SharedReference.shared.synchronize {
                    rsyncparametersrestore.remoteargumentsfilelist()
                } else if config.task == SharedReference.shared.snapshot {
                    rsyncparametersrestore.remoteargumentssnapshotfilelist()
                }
            case .snapshotcatalogsonly:
                rsyncparametersrestore.remoteargumentssnapshotcataloglist()
            }
            return rsyncparametersrestore.computedarguments
        }
        return nil
    }

    init(config: SynchronizeConfiguration?, filelisttask: Enumrestorefiles) {
        self.config = config
        self.filelisttask = filelisttask
    }
}

// swiftlint:enable line_length
