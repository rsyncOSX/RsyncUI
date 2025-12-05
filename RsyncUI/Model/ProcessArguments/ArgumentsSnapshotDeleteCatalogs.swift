//
//  ArgumentsSnapshotDeleteCatalogs.swift
//  RsyncOSX
//
//  Created by Thomas Evensen on 26.01.2018.
//  Copyright © 2018 Thomas Evensen. All rights reserved.
//

import Foundation
import RsyncArguments

@MainActor
final class ArgumentsSnapshotDeleteCatalogs {
    private var config: SynchronizeConfiguration?
    private var arguments: [String]?
    private var command: String?
    private var remotecatalog: String

    private func argumentssnapshotdeletecatalogs() -> [String]? {
        if let config {
            let sshparameters = SSHParams().sshparams(config: config)
            let sshargs = SnapshotDelete(sshParameters: sshparameters)
            if config.offsiteServer.isEmpty == false {
                command = sshargs.remoteCommand
            } else {
                command = sshargs.localCommand
            }
            return sshargs.snapshotDelete(remoteCatalog: remotecatalog)
        }
        return nil
    }

    func getArguments() -> [String]? { arguments }
    func getCommand() -> String? { command }

    init(config: SynchronizeConfiguration, remotecatalog: String) {
        self.config = config
        self.remotecatalog = remotecatalog
        arguments = argumentssnapshotdeletecatalogs()
    }
}
