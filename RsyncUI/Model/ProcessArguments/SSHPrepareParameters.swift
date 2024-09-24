//
//  SSHPrepareParameters.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 24/09/2024.
//

import Foundation
import RsyncArguments

@MainActor
final class SSHPrepareParameters {
    var sshparameters: SSHParameters

    init(config: SynchronizeConfiguration) {
        sshparameters = SSHParameters(offsiteServer: config.offsiteServer,
                                      offsiteUsername: config.offsiteUsername,
                                      sshport: String(config.sshport ?? -1),
                                      sshkeypathandidentityfile: config.sshkeypathandidentityfile,
                                      sharedsshport: String(SharedReference.shared.sshport ?? -1),
                                      sharedsshkeypathandidentityfile: SharedReference.shared.sshkeypathandidentityfile,
                                      rsyncversion3: SharedReference.shared.rsyncversion3)
    }
}
