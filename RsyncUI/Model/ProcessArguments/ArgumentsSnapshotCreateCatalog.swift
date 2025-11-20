//
//  ArgumentsSnapshotCreateCatalog.swift
//  RsyncOSX
//
//  Created by Thomas Evensen on 17.01.2018.
//  Copyright © 2018 Thomas Evensen. All rights reserved.
//
// swiftlint:disable line_length

import Foundation
import RsyncArguments

@MainActor
final class ArgumentsSnapshotCreateCatalog {
    private var config: SynchronizeConfiguration?
    private var arguments: [String]?
    private var command: String?

    func argumentssshcommands() -> [String]? {
        if let config {
            let sshparameters = SSHParameters(
                offsiteServer: config.offsiteServer,
                offsiteUsername: config.offsiteUsername,
                sshport: String(config.sshport ?? -1),
                sshkeypathandidentityfile: config.sshkeypathandidentityfile ?? "",
                sharedsshport: String(SharedReference.shared.sshport ?? -1),
                sharedsshkeypathandidentityfile: SharedReference.shared.sshkeypathandidentityfile,
                rsyncversion3: SharedReference.shared.rsyncversion3
            )
            let sshcommands = SnapshotDelete(sshParameters: sshparameters)
            /*
             let sshparameter = SSHPrepareParameters(config: config).sshparameters
             let snapshotcreatecatalog = SnapshotCreateRootCatalog(sshparameters: sshparameter)

             snapshotcreatecatalog.initialise_setsshidentityfileandsshport()
             command = snapshotcreatecatalog.remotecommand
             return snapshotcreatecatalog.snapshotcreaterootcatalog(offsiteCatalog: config.offsiteCatalog)
              */
        }

        return nil
    }

    func getArguments() -> [String]? { arguments }
    func getCommand() -> String? { command }

    init(config: SynchronizeConfiguration?) {
        self.config = config
        arguments = argumentssshcommands()
    }
}

// swiftlint:enable line_length
