//
//  ArgumentsRestore.swift
//  RsyncOSX
//
//  Created by Thomas Evensen on 13/10/2019.
//  Copyright © 2019 Thomas Evensen. All rights reserved.
//

import Foundation
import RsyncArguments

@MainActor
final class ArgumentsRestore {
    var config: SynchronizeConfiguration?
    var restoresnapshotbyfiles: Bool = false

    func argumentsrestore(dryRun: Bool, forDisplay: Bool) -> [String]? {
        if let config {
            let params = Params().params(config: config)
            let rsyncparametersrestore = RsyncParametersRestore(parameters: params)
            do {
                try rsyncparametersrestore.argumentsRestore(forDisplay: forDisplay,
                                                            verify: false,
                                                            dryrun: dryRun,
                                                            restoreSnapshotByFiles: restoresnapshotbyfiles)
                return rsyncparametersrestore.computedArguments
            } catch {
                return nil
            }
        }
        return nil
    }

    init(config: SynchronizeConfiguration?, restoresnapshotbyfiles: Bool) {
        self.config = config
        self.restoresnapshotbyfiles = restoresnapshotbyfiles
    }
}
