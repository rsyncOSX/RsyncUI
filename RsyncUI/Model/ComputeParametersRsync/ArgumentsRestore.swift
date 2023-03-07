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
                    remoteargs(config: config)
                } else {
                    remoteargssnapshot(config: config)
                }
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
