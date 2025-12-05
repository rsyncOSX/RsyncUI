//
//  ArgumentsSynchronize.swift
//  RsyncOSX
//
//  Created by Thomas Evensen on 13/10/2019.
//  Copyright © 2019 Thomas Evensen. All rights reserved.
//

import Foundation
import RsyncArguments

@MainActor
final class ArgumentsSynchronize {
    var config: SynchronizeConfiguration?

    func argumentsforpushlocaltoremotewithparameters(dryRun: Bool, forDisplay: Bool, keepdelete: Bool) -> [String]? {
        if let config {
            let params = Params().params(config: config)
            let rsyncparameterssynchronize = RsyncParametersSynchronize(parameters: params)
            do {
                try rsyncparameterssynchronize.argumentsForPushLocalToRemoteWithParameters(forDisplay: forDisplay,
                                                                                           verify: false,
                                                                                           dryrun: dryRun,
                                                                                           keepDelete: keepdelete)
                return rsyncparameterssynchronize.computedArguments
            } catch {
                return nil
            }
        }
        return nil
    }

    func argumentssynchronize(dryRun: Bool, forDisplay: Bool) -> [String]? {
        if let config {
            let params = Params().params(config: config)
            let rsyncparameterssynchronize = RsyncParametersSynchronize(parameters: params)

            switch config.task {
            case SharedReference.shared.synchronize:
                do {
                    try rsyncparameterssynchronize.argumentsForSynchronize(forDisplay: forDisplay,
                                                                           verify: false,
                                                                           dryrun: dryRun)
                    return rsyncparameterssynchronize.computedArguments
                } catch {
                    return nil
                }
            case SharedReference.shared.snapshot:
                do {
                    try rsyncparameterssynchronize.argumentsForSynchronizeSnapshot(forDisplay: forDisplay,
                                                                                   verify: false,
                                                                                   dryrun: dryRun)
                    return rsyncparameterssynchronize.computedArguments
                } catch {
                    return nil
                }
            case SharedReference.shared.syncremote:
                do {
                    try rsyncparameterssynchronize.argumentsForSynchronizeRemote(forDisplay: forDisplay,
                                                                                 verify: false,
                                                                                 dryrun: dryRun)
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
