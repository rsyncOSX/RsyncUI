//
//  ArgumentsRestore.swift
//  RsyncOSX
//
//  Created by Thomas Evensen on 13/10/2019.
//  Copyright © 2019 Thomas Evensen. All rights reserved.
//
// swiftlint:disable line_length

import Foundation
import OSLog
import RsyncArguments

@MainActor
final class ArgumentsRestore {
    var config: SynchronizeConfiguration?
    var restoresnapshotbyfiles: Bool = false

    func argumentsrestore(dryRun: Bool, forDisplay: Bool) -> [String]? {
        if let config {
            Logger.process.info("ArgumentsRestore: using RsyncParametersRestore() from RsyncArguments")
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
            rsyncparametersrestore.argumentsrestore(forDisplay: forDisplay, verify: false, dryrun: dryRun, restoresnapshotbyfiles: restoresnapshotbyfiles)
            return rsyncparametersrestore.computedarguments
        }

        return nil
    }

    /*
     if snapshot {
         if restoresnapshotbyfiles == true {
             // This is a hack for fixing correct restore for files
             // from a snapshot. The last snapshot is base for restore
             // of files. The correct snapshot is added within the
             // ObserveableRestore which is used within the RestoreView
             // --archive --verbose --compress --delete -e "ssh -i ~/.ssh_rsyncosx/rsyncosx -p 22"
             // --exclude-from=/Users/thomas/Documents/excludersync/exclude-list-github.txt --dry-run --stats
             // thomas@backup:/backups/snapshots/Github/85/AlertToast /Users/thomas/tmp
             remoteargs(config: config)
         } else {
             // --archive --verbose --compress --delete -e "ssh -i ~/.ssh_rsyncosx/rsyncosx -p 22"
             // --exclude-from=/Users/thomas/Documents/excludersync/exclude-list-github.txt --dry-run --stats
             // thomas@backup:/backups/snapshots/Github/85/ /Users/thomas/tmp
             remoteargssnapshot(config: config)
         }
     } else {
         // --archive --verbose --compress --delete -e "ssh -i ~/.ssh_rsyncosx/rsyncosx -p 22" --backup
         // --backup-dir=../backup_Documents --dry-run --stats thomas@backup:/backups/Documents/
         // Users/thomas/tmp
         remoteargs(config: config)
     }
     */

    init(config: SynchronizeConfiguration?, restoresnapshotbyfiles: Bool) {
        self.config = config
        self.restoresnapshotbyfiles = restoresnapshotbyfiles
    }
}

// swiftlint:enable line_length
