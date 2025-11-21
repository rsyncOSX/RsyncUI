//
//  ArgumentsVerify.swift
//  RsyncOSX
//
//  Created by Thomas Evensen on 13/10/2019.
//  Copyright © 2019 Thomas Evensen. All rights reserved.
//
// swiftlint:disable line_length

import Foundation
import RsyncArguments

@MainActor
final class ArgumentsVerify {
    var config: SynchronizeConfiguration?

    func argumentsverify(forDisplay: Bool) -> [String]? {
        if let config {
            let params = Params().params(config: config)
            let rsyncparameterssynchronize = RsyncParametersSynchronize(parameters: params)

            switch config.task {
            case SharedReference.shared.synchronize:
                do {
                    try rsyncparameterssynchronize.argumentsForSynchronize(forDisplay: forDisplay,
                                                                           verify: true,
                                                                           dryrun: true)
                    return rsyncparameterssynchronize.computedArguments
                } catch {
                    return nil
                }
            case SharedReference.shared.snapshot:
                do {
                    try rsyncparameterssynchronize.argumentsForSynchronizeSnapshot(forDisplay: forDisplay,
                                                                                   verify: true,
                                                                                   dryrun: true)
                    return rsyncparameterssynchronize.computedArguments
                } catch {
                    return nil
                }
            case SharedReference.shared.syncremote:
                do {
                    try rsyncparameterssynchronize.argumentsForSynchronizeRemote(forDisplay: forDisplay,
                                                                                 verify: true,
                                                                                 dryrun: true)
                    return rsyncparameterssynchronize.computedArguments
                } catch {
                    return nil
                }
            default:
                break
            }
        }
        return nil
    }

    init(config: SynchronizeConfiguration?) {
        self.config = config
    }
}

// swiftlint:enable line_length
