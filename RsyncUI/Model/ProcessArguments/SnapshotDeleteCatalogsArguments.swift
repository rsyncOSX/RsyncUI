//
//  SnapshotDeleteCatalogsArguments.swift
//  RsyncOSX
//
//  Created by Thomas Evensen on 26.01.2018.
//  Copyright © 2018 Thomas Evensen. All rights reserved.
//

import Foundation

final class SnapshotDeleteCatalogsArguments {
    private var config: SynchronizeConfiguration?
    private var args: [String]?
    private var command: String?
    private var remotecatalog: String?

    private func remotearguments() {
        var remotearg: String?
        guard config != nil else { return }
        if config?.sshport != nil {
            args?.append("-p")
            args?.append(String(config!.sshport!))
        }
        if config?.offsiteServer.isEmpty == false {
            remotearg = (config?.offsiteUsername ?? "") + "@" + (config?.offsiteServer ?? "")
            args?.append(remotearg ?? "")
        }
        let remotecommand = "rm -rf " + (remotecatalog ?? "")
        args?.append(remotecommand)
    }

    private func localarguments() {
        guard config != nil else { return }
        let remotecatalog = remotecatalog!
        args?.append("-rf")
        args?.append(remotecatalog)
    }

    func getArguments() -> [String]? {
        args
    }

    func getCommand() -> String? {
        command
    }

    init(config: SynchronizeConfiguration, remotecatalog: String) {
        args = [String]()
        self.config = config
        self.remotecatalog = remotecatalog
        if config.offsiteServer.isEmpty == false {
            remotearguments()
            command = "/usr/bin/ssh"
        } else {
            localarguments()
            command = "/bin/rm"
        }
    }
}
