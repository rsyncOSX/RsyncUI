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
        let present = sshcreatekey?.validatepublickeypresent()
        if present == false {
            // If new keypath is set create it
            sshcreatekey?.createsshkeyrootpath()
            // Create keys
            arguments = sshcreatekey?.argumentscreatekey()
            // command = "/usr/bin/ssh-keygen"
            command = sshcreatekey?.createkeycommand
            executesshcreatekeys()
            return true
        } else {
            return false
        }
    }

    func validatepublickeypresent() -> Bool {
        sshcreatekey?.validatepublickeypresent() ?? false
    }

    // Execute command
    func executesshcreatekeys() {
        guard arguments != nil else { return }
        let process = ProcessCommand(command: command,
                                     arguments: arguments,
                                     processtermination: processtermination)
        process.executeProcess()
    }

    func processtermination(stringoutputfromrsync: [String]?) {
        Logfile(TrimOutputFromRsync(stringoutputfromrsync ?? []).trimmeddata, error: true)
    }

    init() {
        sshcreatekey = SSHCreateKey(sharedsshport: String(SharedReference.shared.sshport ?? -1),
                                    sharedsshkeypathandidentityfile: SharedReference.shared.sshkeypathandidentityfile)
    }
}
