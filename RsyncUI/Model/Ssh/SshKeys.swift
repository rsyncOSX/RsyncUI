//
//  SshKeys.swift
//  RsyncOSX
//
//  Created by Thomas Evensen on 23.04.2017.
//  Copyright © 2017 Thomas Evensen. All rights reserved.
//

import Cocoa
import Foundation
import SSHCreateKey

@MainActor
final class SshKeys: PropogateError {
    var command: String?
    var arguments: [String]?

    var sshcreatekey: SSHCreateKey?

    // Create rsa keypair
    func createPublicPrivateRSAKeyPair() -> Bool {
        do {
            let present = try sshcreatekey?.islocalpublicrsakeypresent()
            if present == false {
                // If new keypath is set create it
                sshcreatekey?.createsshkeyrootpath()
                // Create keys
                arguments = sshcreatekey?.argumentscreatekey()
                // command = "/usr/bin/ssh-keygen"
                command = sshcreatekey?.createkeycommand
                executesshcreatekeys()
                return true
            }
        } catch let e {
            let error = e
            propogateerror(error: error)
            return false
        }
        return false
    }

    // Secure copy of public key from local to remote catalog
    func copylocalpubrsakeyfile(_ remote: UniqueserversandLogins?) -> String {
        let offsiteServer = remote?.offsiteServer ?? ""
        let offsiteUsername = remote?.offsiteUsername ?? ""
        return sshcreatekey?.argumentssshcopyid(offsiteServer: offsiteServer,
                                                offsiteUsername: offsiteUsername) ?? ""
    }

    // Check for remote pub keys
    func verifyremotekey(_ remote: UniqueserversandLogins?) -> String {
        let offsiteServer = remote?.offsiteServer ?? ""
        let offsiteUsername = remote?.offsiteUsername ?? ""
        return sshcreatekey?.argumentsverifyremotepublicsshkey(offsiteServer: offsiteServer,
                                                        offsiteUsername: offsiteUsername) ?? ""
    }

    func validatepublickeypresent() -> Bool {
        sshcreatekey?.validatepublickeypresent() ?? false
    }

    // Execute command
    func executesshcreatekeys() {
        guard arguments != nil else { return }
        let process = CommandProcess(command: command,
                                     arguments: arguments,
                                     processtermination: processtermination)
        process.executeProcess()
    }

    func processtermination(data: [String]?) {
        Logfile(TrimOutputFromRsync(data ?? []).trimmeddata, error: true)
    }

    init() {
        sshcreatekey = SSHCreateKey(sharedsshport: String(SharedReference.shared.sshport ?? -1),
                                    sharedsshkeypathandidentityfile: SharedReference.shared.sshkeypathandidentityfile)
    }
}
