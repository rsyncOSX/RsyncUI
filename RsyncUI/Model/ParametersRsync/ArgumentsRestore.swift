//
//  ArgumentsRestore.swift
//  RsyncOSX
//
//  Created by Thomas Evensen on 13/10/2019.
//  Copyright © 2019 Thomas Evensen. All rights reserved.
//
// swiftlint:disable line_length

import Foundation
import RsyncArguments

@MainActor
final class ArgumentsRestore {
    var config: SynchronizeConfiguration?
    var restoresnapshotbyfiles: Bool = false

    func argumentsrestore(dryRun: Bool, forDisplay: Bool) -> [String]? {
        if let config {
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

    init(config: SynchronizeConfiguration?, restoresnapshotbyfiles: Bool) {
        self.config = config
        self.restoresnapshotbyfiles = restoresnapshotbyfiles
    }
}

// swiftlint:enable line_length
