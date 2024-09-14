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
final class ObservableSSH: PropogateError {
    // Global SSH parameters
    // Have to convert String -> Int before saving
    // Set the current value as placeholder text
    var sshportnumber: String = ""
    // SSH keypath and identityfile, the settings View is picking up the current value
    // Set the current value as placeholder text
    var sshkeypathandidentityfile: String = ""
    // Default RSA sshkeypath og port
    let defaultsshkeypathandidentityfile = "~/.ssh/id_rsa"
    let defaultsshport = "22"

    var sshcreatekey: SSHCreateKey?

    func sshkeypath(_ keypath: String) {
        guard keypath.isEmpty == false else {
            SharedReference.shared.sshkeypathandidentityfile = nil
            return
        }
        do {
            let verified = try sshcreatekey?.verifysshkeypath(keypath)
            if verified == true {
                SharedReference.shared.sshkeypathandidentityfile = keypath
                // Save port number also
                if let port = Int(sshportnumber) {
                    SharedReference.shared.sshport = port
                }
            }
        } catch let e {
            let error = e
            propogateerror(error: error)
            return
        }
    }

    func sshport(_ port: String) {
        guard port.isEmpty == false else {
            SharedReference.shared.sshport = nil
            return
        }
        do {
            let verified = try sshcreatekey?.verifysshport(port)
            if verified == true {
                SharedReference.shared.sshport = Int(port)
                SharedReference.shared.sshkeypathandidentityfile = sshkeypathandidentityfile
            }
        } catch let e {
            let error = e
            propogateerror(error: error)
            return
        }
    }

    init() {
        sshcreatekey = SSHCreateKey(sharedsshport: String(SharedReference.shared.sshport ?? -1),
                                    sharedsshkeypathandidentityfile: SharedReference.shared.sshkeypathandidentityfile)
    }
}
