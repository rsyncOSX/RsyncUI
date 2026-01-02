//
//  SSHParams.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 20/11/2025.
//

import Foundation
import RsyncArguments

@MainActor
struct SSHParams {
    func sshparams(
        config: SynchronizeConfiguration) -> SSHParameters {
        var sshport = ""
        var sshkeypathandidentityfile = ""
        if let configsshport = config.sshport, configsshport != -1 {
            sshport = String(configsshport)
        }
        if let configurationsshcreatekey = config.sshkeypathandidentityfile {
            sshkeypathandidentityfile = configurationsshcreatekey
        }

        return SSHParameters(
            offsiteServer: config.offsiteServer,
            offsiteUsername: config.offsiteUsername,
            sshport: String(sshport),
            sshkeypathandidentityfile: sshkeypathandidentityfile,
            sharedsshport: String(SharedReference.shared.sshport ?? -1),
            sharedsshkeypathandidentityfile: SharedReference.shared.sshkeypathandidentityfile,
            rsyncversion3: SharedReference.shared.rsyncversion3
        )
    }
}
