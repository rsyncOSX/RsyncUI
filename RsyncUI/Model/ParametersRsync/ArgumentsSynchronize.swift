//
//  ArgumentsSynchronize.swift
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
final class ArgumentsSynchronize {
    var config: SynchronizeConfiguration?
    
    func argumentsforpushlocaltoremote(dryRun: Bool, forDisplay: Bool) -> [String]? {
        if let config {
            Logger.process.info("ArgumentsSynchronize: using argumentsforpushlocaltoremote() - RsyncArguments")
            Logger.process.info("ArgumentsSynchronize: using argumentsforpushlocaltoremote() --delete is removed")
            if let parameters = PrepareParameters(config: config).parameters {
                let rsyncparameterssynchronize =
                RsyncParametersSynchronize(parameters: parameters)
                rsyncparameterssynchronize.argumentsforpushlocaltoremote(forDisplay: forDisplay, verify: false, dryrun: dryRun)
                return rsyncparameterssynchronize.computedarguments
            }
        }
        return nil
    }

    func argumentssynchronize(dryRun: Bool, forDisplay: Bool) -> [String]? {
        if let config {
            Logger.process.info("ArgumentsSynchronize: using argumentssynchronize() - RsyncArguments")
            if let parameters = PrepareParameters(config: config).parameters {
                let rsyncparameterssynchronize =
                    RsyncParametersSynchronize(parameters: parameters)
                switch config.task {
                case SharedReference.shared.synchronize:
                    rsyncparameterssynchronize.argumentsforsynchronize(forDisplay: forDisplay,
                                                                       verify: false, dryrun: dryRun)
                case SharedReference.shared.snapshot:
                    rsyncparameterssynchronize.argumentsforsynchronizesnapshot(forDisplay: forDisplay,
                                                                               verify: false, dryrun: dryRun)
                case SharedReference.shared.syncremote:
                    rsyncparameterssynchronize.argumentsforsynchronizeremote(forDisplay: forDisplay,
                                                                             verify: false, dryrun: dryRun)
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
