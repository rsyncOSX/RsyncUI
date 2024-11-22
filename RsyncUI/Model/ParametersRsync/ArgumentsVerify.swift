//
//  ArgumentsVerify.swift
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
final class ArgumentsVerify {
    var config: SynchronizeConfiguration?

    func argumentsverify(forDisplay: Bool) -> [String]? {
        if let config {
            Logger.process.info("ArgumentsVerify: using argumentsverify() - RsyncArguments")
            if let parameters = PrepareParameters(config: config).parameters {
                let rsyncparameterssynchronize =
                    RsyncParametersSynchronize(parameters: parameters)
                switch config.task {
                case SharedReference.shared.synchronize:
                    rsyncparameterssynchronize.argumentsforsynchronize(forDisplay: forDisplay,
                                                                       verify: true, dryrun: true)
                case SharedReference.shared.snapshot:
                    rsyncparameterssynchronize.argumentsforsynchronizesnapshot(forDisplay: forDisplay,
                                                                               verify: true, dryrun: true)
                case SharedReference.shared.syncremote:
                    rsyncparameterssynchronize.argumentsforsynchronizeremote(forDisplay: forDisplay,
                                                                             verify: true, dryrun: true)
                default:
                    break
                }
                return rsyncparameterssynchronize.computedarguments
            }
        }
        return nil
    }

    init(config: SynchronizeConfiguration?) {
        self.config = config
    }
}

// swiftlint:enable line_length
