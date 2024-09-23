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
            if let parameters = PrepareParameters(config: config).parameters {
                let rsyncparametersrestore =
                RsyncParametersRestore(parameters: parameters)
                rsyncparametersrestore.argumentsrestore(forDisplay: forDisplay,
                                                        verify: false, dryrun: dryRun,
                                                        restoresnapshotbyfiles: restoresnapshotbyfiles)
                return rsyncparametersrestore.computedarguments
            }
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
