//
//  ArgumentsVerifyRemote.swift
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
final class ArgumentsVerifyRemote {
    var config: SynchronizeConfiguration?

    func argumentsverifyremote(dryRun: Bool, forDisplay: Bool) -> [String]? {
        if let config {
            Logger.process.info("ArgumentsVerifyRemote: using RsyncParametersVerifyRemote() from RsyncArguments")
            if let parameters = PrepareParameters(config: config).parameters {
                let rsyncparametersrestore =
                    RsyncParametersVerifyRemote(parameters: parameters)
                rsyncparametersrestore.argumentsverifyremote(forDisplay: forDisplay,
                                                             verify: false, dryrun: dryRun)
                return rsyncparametersrestore.computedarguments
            }
        }
        return nil
    }

    func argumentsverifyremotewithparameters(dryRun: Bool, forDisplay: Bool) -> [String]? {
        if let config {
            Logger.process.info("ArgumentsVerifyRemoteWithParameters: using RsyncParametersVerifyRemote() from RsyncArguments")
            if let parameters = PrepareParameters(config: config).parameters {
                let rsyncparametersrestore =
                    RsyncParametersVerifyRemote(parameters: parameters)
                rsyncparametersrestore.argumentsverifyremotewithparameters(forDisplay: forDisplay,
                                                                           verify: false, dryrun: dryRun, nodelete: true)
                return rsyncparametersrestore.computedarguments
            }
        }
        return nil
    }

    init(config: SynchronizeConfiguration?) {
        self.config = config
    }
}

// swiftlint:enable line_length
