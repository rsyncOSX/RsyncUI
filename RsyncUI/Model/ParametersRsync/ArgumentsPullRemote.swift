//
//  ArgumentsPullRemote.swift
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
final class ArgumentsPullRemote {
    var config: SynchronizeConfiguration?

    func argumentspullremotewithparameters(dryRun: Bool, forDisplay: Bool) -> [String]? {
        if let config {
            Logger.process.info("ArgumentsPullRemote: using argumentspullremotewithparameters() - RsyncArguments")
            Logger.process.info("ArgumentsSynchronize: using argumentspullremotewithparameters() --delete is removed")
            if let parameters = PrepareParameters(config: config).parameters {
                let rsyncparameterspull =
                    RsyncParametersPullRemote(parameters: parameters)
                rsyncparameterspull.argumentspullremotewithparameters(forDisplay: forDisplay,
                                                                      verify: false, dryrun: dryRun)
                return rsyncparameterspull.computedarguments
            }
        }
        return nil
    }

    init(config: SynchronizeConfiguration?) {
        self.config = config
    }
}

// swiftlint:enable line_length
