//
//  ArgumentsSnapshotDeleteCatalogs.swift
//  RsyncOSX
//
//  Created by Thomas Evensen on 26.01.2018.
//  Copyright © 2018 Thomas Evensen. All rights reserved.
//
// swiftlint:disable line_length

import Foundation
import OSLog
import RsyncArguments

@MainActor
final class ArgumentsSnapshotDeleteCatalogs {
    private var config: SynchronizeConfiguration?
    private var arguments: [String]?
    private var command: String?
    private var remotecatalog: String?

    func argumentssshcommands() -> [String]? {
        if let config {
            Logger.process.info("ArgumentsSnapshotDeleteCatalogs: using RsyncParametersSynchronize() from RsyncArguments")
            let snapshotdelete = SnapshotDelete(
                offsiteServer: config.offsiteServer,
                offsiteUsername: config.offsiteUsername,
                sshport: String(config.sshport ?? -1),
                sshkeypathandidentityfile: config.sshkeypathandidentityfile ?? "",
                sharedsshport: String(SharedReference.shared.sshport ?? -1),
                sharedsshkeypathandidentityfile: SharedReference.shared.sshkeypathandidentityfile,
                rsyncversion3: SharedReference.shared.rsyncversion3
            )

            snapshotdelete.initialise_setsshidentityfileandsshport()

            if config.offsiteServer.isEmpty == false {
                command = snapshotdelete.remotecommand
            } else {
                command = snapshotdelete.localcommand
            }
            if let remotecatalog {
                return snapshotdelete.snapshotdelete(remotecatalog: remotecatalog)
            }
        }
        return nil
    }

    func getArguments() -> [String]? { arguments }
    func getCommand() -> String? { command }

    init(config: SynchronizeConfiguration, remotecatalog: String) {
        self.config = config
        self.remotecatalog = remotecatalog
        arguments = argumentssshcommands()
    }
}

// swiftlint:enable line_length
