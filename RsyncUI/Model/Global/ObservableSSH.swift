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
    var sshportnumber: String = ""
    // SSH keypath and identityfile, the settings View is picking up the current value
    // Set the current value as placeholder text
    var sshkeypathandidentityfile: String = ""
    var sshcreatekey: SSHCreateKey?

    func sshkeypath(_ keypath: String) -> Bool {
        guard keypath.isEmpty == false else {
            SharedReference.shared.sshkeypathandidentityfile = nil
            return false
        }
        do {
            let verified = try sshcreatekey?.verifysshkeypath(keypath)
            if verified == true {
                SharedReference.shared.sshkeypathandidentityfile = keypath
            }
            return true
        } catch {
            return false
        }
    }

    func sshport(_ port: String) -> Bool {
        guard port.isEmpty == false else {
            SharedReference.shared.sshport = nil
            return false
        }
        do {
            let verified = try sshcreatekey?.verifysshport(port)
            if verified == true {
                SharedReference.shared.sshport = Int(port)
            }
            return true
        } catch {
            return false
        }
    }

    init() {
        sshcreatekey = SSHCreateKey(sharedsshport: String(SharedReference.shared.sshport ?? -1),
                                    sharedsshkeypathandidentityfile: SharedReference.shared.sshkeypathandidentityfile)
    }
}
