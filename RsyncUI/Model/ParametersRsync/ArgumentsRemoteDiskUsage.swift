//
//  ArgumentsRemoteDiskUsage.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 01/12/2024.
//

import Foundation
import RsyncArguments

@MainActor
final class ArgumentsRemoteDiskUsage {
    var config: SynchronizeConfiguration?
    private var remotecatalog: String?
    private var command: String?

    func argumentsremotediskusage() -> [String]? {
        if let config {
            let sshparameter = SSHPrepareParameters(config: config).sshparameters
            let diskusage = RemoteSize(sshparameters: sshparameter)
            diskusage.initialise_setsshidentityfileandsshport()
            
            if config.offsiteServer.isEmpty == false {
                command = diskusage.remotecommand
            } else {
                return nil
            }
            
            if var remotecatalog {
                if remotecatalog.hasSuffix("/") {
                    remotecatalog.removeLast()
                }
                return diskusage.remotedisksize(remotecatalog: remotecatalog)
            }
        }
        return nil
    }

    func getCommand() -> String? { command }

    init(config: SynchronizeConfiguration, remotecatalog: String) {
        self.config = config
        self.remotecatalog = remotecatalog
    }
}
