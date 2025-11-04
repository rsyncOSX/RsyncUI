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
import ProcessCommand

@MainActor
final class SshKeys {
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
        let handlers = ProcessHandlersCommand(
            processtermination: processtermination,
            checklineforerror: TrimOutputFromRsync().checkforrsyncerror,
            updateprocess: SharedReference.shared.updateprocess,
            propogateerror: { error in
                SharedReference.shared.errorobject?.alert(error: error)
            },
            logger: { command, output in
                _ = await ActorLogToFile(command, output)
            },
            rsyncui: true
        )
        
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

    func processtermination(stringoutputfromrsync: [String]?, _: Bool) {
        Task {
            await ActorLogToFile(command ?? "", TrimOutputFromRsync(stringoutputfromrsync ?? []).trimmeddata)
        }
    }

    init() {
        sshcreatekey = SSHCreateKey(sharedsshport: String(SharedReference.shared.sshport ?? -1),
                                    sharedsshkeypathandidentityfile: SharedReference.shared.sshkeypathandidentityfile)
    }
}
