//
//  ObservableSSH.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 14/03/2021.
//

import Foundation
import Observation
import SSHCreateKey

@Observable @MainActor
final class ObservableSSH {
    // Global SSH parameters
    // Have to convert String -> Int before saving
    // Set the current value as placeholder text
    var sshportnumber: String = .init(SharedReference.shared.sshport ?? 22)
    // SSH keypath and identityfile, the settings View is picking up the current value
    // Set the current value as placeholder text
    var sshkeypathandidentityfile: String = SharedReference.shared.sshkeypathandidentityfile ?? ""
    var sshcreatekey: SSHCreateKey?

    init() {
        if let sshport = SharedReference.shared.sshport, let sshkeypathandidentityfile = SharedReference.shared.sshkeypathandidentityfile {
            sshcreatekey = SSHCreateKey(sharedSSHPort: String(sshport),
                                        sharedSSHKeyPathAndIdentityFile: sshkeypathandidentityfile)
        }
    }
}
