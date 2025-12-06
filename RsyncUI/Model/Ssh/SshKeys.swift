//
//  SshKeys.swift
//  RsyncOSX
//
//  Created by Thomas Evensen on 23.04.2017.
//  Copyright © 2017 Thomas Evensen. All rights reserved.
//

import Cocoa
import Foundation
import ProcessCommand
import SSHCreateKey

@MainActor
final class SshKeys {
    var command: String?
    var arguments: [String]?

    var sshcreatekey: SSHCreateKey?

    // Create rsa keypair
    func createPublicPrivateRSAKeyPair() -> Bool {
        let present = sshcreatekey?.validatePublicKeyPresent()
        if present == false {
            do {
                // If new keypath is set create it
                try sshcreatekey?.createSSHKeyRootPath()
                // Create keys
                arguments = try sshcreatekey?.argumentsCreateKey()
                // command = "/usr/bin/ssh-keygen"
                command = sshcreatekey?.createKeyCommand
                executesshcreatekeys()
                return true
            } catch {
                return false
            }

        } else {
            return false
        }
    }

    func validatepublickeypresent() -> Bool {
        sshcreatekey?.validatePublicKeyPresent() ?? false
    }

    // Execute command
    func executesshcreatekeys() {
        guard arguments != nil else { return }

        let handlers = CreateCommandHandlers().createcommandhandlers(
            processTermination: processTermination)

        let process = ProcessCommand(command: command,
                                     arguments: arguments,
                                     handlers: handlers)
        do {
            try process.executeProcess()
        } catch let e {
            let error = e
            SharedReference.shared.errorobject?.alert(error: error)
        }
    }

    func processTermination(stringoutputfromrsync: [String]?, _: Bool) {
        Task {
            await ActorLogToFile(command ?? "", TrimOutputFromRsync(stringoutputfromrsync ?? []).trimmeddata)
        }
    }

    init() {
        sshcreatekey = SSHCreateKey(sharedSSHPort: String(SharedReference.shared.sshport ?? -1),
                                    sharedSSHKeyPathAndIdentityFile: SharedReference.shared.sshkeypathandidentityfile)
    }
}
