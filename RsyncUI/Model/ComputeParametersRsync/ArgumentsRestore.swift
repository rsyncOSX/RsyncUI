//
//  ArgumentsRestore.swift
//  RsyncOSX
//
//  Created by Thomas Evensen on 13/10/2019.
//  Copyright © 2019 Thomas Evensen. All rights reserved.
//

import Foundation

final class ArgumentsRestore: ComputeRsyncParameters {
    var config: Configuration?
    var restoresnapshotbyfiles: Bool = false

    func argumentsrestore(dryRun: Bool, forDisplay: Bool, tmprestore: Bool) -> [String]? {
        if let config = config {
            localCatalog = config.localCatalog
            if config.snapshotnum != nil {
                if restoresnapshotbyfiles == true {
                    // This is a hack for fixing correct restore for files
                    // from a snapshot. The last snapshot is base for restore
                    // of files. The correct snapshot is added within the
                    // ObserveableRestore which is used within the RestoreView
                    remoteargs(config: config)
                } else {
                    remoteargssnapshot(config: config)
                }
            } else {
                remoteargs(config: config)
            }
            setParameters1To6(config: config, dryRun: dryRun, forDisplay: forDisplay, verify: false)
            setParameters8To14(config: config, dryRun: dryRun, forDisplay: forDisplay)
            argumentsforrestore(dryRun: dryRun, forDisplay: forDisplay, tmprestore: tmprestore)
            return arguments
        }
        return nil
    }

    init(config: Configuration?, restoresnapshotbyfiles: Bool) {
        super.init()
        self.config = config
        self.restoresnapshotbyfiles = restoresnapshotbyfiles
    }
}
