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
        let sshport = SharedReference.shared.sshport
        let sshkeypathandidentityfile = SharedReference.shared.sshkeypathandidentityfile

        if let port = sshport, let keypath = sshkeypathandidentityfile {
            // Both values are not nil
            sshcreatekey = SSHCreateKey(sharedSSHPort: String(port),
                                        sharedSSHKeyPathAndIdentityFile: keypath)
        } else if let port = sshport {
            // Only port is not nil
            sshcreatekey = SSHCreateKey(sharedSSHPort: String(port),
                                        sharedSSHKeyPathAndIdentityFile: nil)
        } else if let keypath = sshkeypathandidentityfile {
            // Only keypath is not nil
            sshcreatekey = SSHCreateKey(sharedSSHPort: nil,
                                        sharedSSHKeyPathAndIdentityFile: keypath)
        }
        // If both are nil, sshcreatekey remains nil
    }
}
