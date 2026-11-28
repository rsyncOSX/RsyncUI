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
    /// A value that is not set must be passed as nil. RsyncArguments treats any
    /// non-nil port, even "", as the task's own setting and then ignores the
    /// global SSH port and key from Settings.
    ///
    /// Rsync daemon tasks (host::module) never get the global values: with
    /// `-e ssh` rsync would run the daemon over SSH instead of connecting to it
    /// on port 873. A daemon task's own SSH settings are still passed as before.
    func sshparams(
        config: SynchronizeConfiguration,
        globalPort: Int? = SharedReference.shared.sshport,
        globalKey: String? = SharedReference.shared.sshkeypathandidentityfile
    ) -> SSHParameters {
        let isDaemon = config.rsyncdaemon == 1
        return SSHParameters(
            offsiteServer: config.offsiteServer,
            offsiteUsername: config.offsiteUsername,
            sshport: Self.portString(config.sshport),
            sshkeypathandidentityfile: Self.keyString(config.sshkeypathandidentityfile),
            sharedsshport: isDaemon ? nil : Self.portString(globalPort),
            sharedsshkeypathandidentityfile: isDaemon ? nil : Self.keyString(globalKey),
            rsyncversion3: SharedReference.shared.rsyncversion3
        )
    }

    /// nil when no port is set (-1 is the stored "not set" value).
    static func portString(_ port: Int?) -> String? {
        guard let port, port != -1 else { return nil }
        return String(port)
    }

    /// nil when no key path is set.
    static func keyString(_ key: String?) -> String? {
        guard let key, key.isEmpty == false else { return nil }
        return key
    }
}
