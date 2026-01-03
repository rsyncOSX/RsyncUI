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
        var sharedsshport = ""
        var sharedsshkeypathandidentityfile = ""

        if let configsshport = config.sshport, configsshport != -1 {
            sshport = String(configsshport)
        }
        if let configurationsshcreatekey = config.sshkeypathandidentityfile {
            sshkeypathandidentityfile = configurationsshcreatekey
        }
        if let configsharedsshport = SharedReference.shared.sshport, configsharedsshport != -1 {
            sharedsshport = String(configsharedsshport)
        }
        if let configsharedsshcreatekey = SharedReference.shared.sshkeypathandidentityfile {
            sharedsshkeypathandidentityfile = configsharedsshcreatekey
        }
        return SSHParameters(
            offsiteServer: config.offsiteServer,
            offsiteUsername: config.offsiteUsername,
            sshport: String(sshport),
            sshkeypathandidentityfile: sshkeypathandidentityfile,
            sharedsshport: String(sharedsshport),
            sharedsshkeypathandidentityfile: sharedsshkeypathandidentityfile,
            rsyncversion3: SharedReference.shared.rsyncversion3
        )
    }
}
