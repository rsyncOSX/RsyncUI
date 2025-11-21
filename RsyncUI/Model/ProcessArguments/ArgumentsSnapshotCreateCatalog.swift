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

    private func argumentssnapshotcreatecatalog() -> [String]? {
        if let config {
            let sshparameters = SSHParams().sshparams(config: config)
            let createcatalog = SnapshotCreateRootCatalog(sshParameters: sshparameters)
            command = createcatalog.remoteCommand
            return createcatalog.snapshotCreateRootCatalog(offsiteCatalog: config.offsiteCatalog)
        }

        return nil
    }

    func getArguments() -> [String]? { arguments }
    func getCommand() -> String? { command }

    init(config: SynchronizeConfiguration?) {
        self.config = config
        arguments = argumentssnapshotcreatecatalog()
    }
}

// swiftlint:enable line_length
