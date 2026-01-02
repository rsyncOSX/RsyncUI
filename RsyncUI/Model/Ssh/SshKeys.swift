//
//  SshKeys.swift
//  RsyncUI
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
        } catch let err {
            let error = err
            SharedReference.shared.errorobject?.alert(error: error)
        }
    }

    func processTermination(stringoutputfromrsync: [String]?, _: Bool) {
        Task {
            await ActorLogToFile(command ?? "", TrimOutputFromRsync(stringoutputfromrsync ?? []).trimmeddata)
        }
    }

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
