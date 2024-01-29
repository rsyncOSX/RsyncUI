//
//  ArgumentsRestore.swift
//  RsyncOSX
//
//  Created by Thomas Evensen on 13/10/2019.
//  Copyright © 2019 Thomas Evensen. All rights reserved.
//

import Foundation

final class ArgumentsRestore: ComputeRsyncParameters {
    var config: SynchronizeConfiguration?
    var restoresnapshotbyfiles: Bool = false

    func argumentsrestore(dryRun: Bool, forDisplay: Bool, tmprestore: Bool) -> [String]? {
        if let config = config {
            // Restore arguments
            localCatalog = config.localCatalog
            let snapshot: Bool = (config.snapshotnum != nil) ? true : false
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
            setParameters1To6(config: config, dryRun: dryRun, forDisplay: forDisplay, verify: false)
            setParameters8To14(config: config, dryRun: dryRun, forDisplay: forDisplay)
            argumentsforrestore(dryRun: dryRun, forDisplay: forDisplay, tmprestore: tmprestore)
            return arguments
        }
        return nil
    }

    init(config: SynchronizeConfiguration?, restoresnapshotbyfiles: Bool) {
        super.init()
        self.config = config
        self.restoresnapshotbyfiles = restoresnapshotbyfiles
    }
}
