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
        config: SynchronizeConfiguration) -> SSHParameters
    {
        SSHParameters(
            offsiteServer: config.offsiteServer,
            offsiteUsername: config.offsiteUsername,
            sshport: String(config.sshport ?? -1),
            sshkeypathandidentityfile: config.sshkeypathandidentityfile ?? "",
            sharedsshport: String(SharedReference.shared.sshport ?? -1),
            sharedsshkeypathandidentityfile: SharedReference.shared.sshkeypathandidentityfile,
            rsyncversion3: SharedReference.shared.rsyncversion3
        )
    }
}
