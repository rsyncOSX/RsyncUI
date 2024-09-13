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
            Logger.process.info("ArgumentsVerify: using RsyncParametersSynchronize() from RsyncArguments")
            let rsyncparameterssynchronize =
                RsyncParametersSynchronize(task: config.task,
                                           parameter1: config.parameter1,
                                           parameter2: config.parameter2,
                                           parameter3: config.parameter3,
                                           parameter4: config.parameter4,
                                           parameter5: config.parameter5,
                                           parameter8: config.parameter8,
                                           parameter9: config.parameter9,
                                           parameter10: config.parameter10,
                                           parameter11: config.parameter11,
                                           parameter12: config.parameter12,
                                           parameter13: config.parameter13,
                                           parameter14: config.parameter14,
                                           sshport: String(config.sshport ?? -1),
                                           sshkeypathandidentityfile: config.sshkeypathandidentityfile ?? "",
                                           sharedsshport: String(SharedReference.shared.sshport ?? -1),
                                           sharedsshkeypathandidentityfile: SharedReference.shared.sshkeypathandidentityfile,
                                           localCatalog: config.localCatalog,
                                           offsiteCatalog: config.offsiteCatalog,
                                           offsiteServer: config.offsiteServer,
                                           offsiteUsername: config.offsiteUsername,
                                           sharedpathforrestore: SharedReference.shared.pathforrestore ?? "",
                                           snapshotnum: config.snapshotnum ?? -1,
                                           rsyncdaemon: config.rsyncdaemon ?? -1,
                                           rsyncversion3: SharedReference.shared.rsyncversion3)
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
        return nil
    }

    init(config: SynchronizeConfiguration?) {
        self.config = config
    }
}

// swiftlint:enable line_length
