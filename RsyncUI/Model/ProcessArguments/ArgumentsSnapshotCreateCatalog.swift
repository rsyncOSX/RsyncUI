//
//  ArgumentsSnapshotCreateCatalog.swift
//  RsyncUI
//

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
