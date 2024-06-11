//
//  SshKeys.swift
//  RsyncOSX
//
//  Created by Thomas Evensen on 23.04.2017.
//  Copyright © 2017 Thomas Evensen. All rights reserved.
//

import Cocoa
import Foundation

enum SshError: LocalizedError {
    case notvalidpath
    case sshkeys
    case noslash

    var errorDescription: String? {
        switch self {
        case .notvalidpath:
            return "SSH keypath is not valid"
        case .sshkeys:
            return "SSH RSA keys exist, cannot create"
        case .noslash:
            return "SSH keypath must be like ~/.ssh_keypath/identityfile"
        }
    }
}

final class SshKeys {
    // Process termination and filehandler closures
    var commandCopyPasteTerminal: String?
    var rsaStringPath: String?
    // Arrays listing all key files
    var keyFileStrings: [String]?
    var argumentsssh: ArgumentsSsh?
    var command: String?
    var arguments: [String]?
    // All paths for ssh
    let path = SSHpath()

    // Create rsa keypair
    func createPublicPrivateRSAKeyPair() -> Bool {
        do {
            let present = try islocalpublicrsakeypresent()
            if present == false {
                // If new keypath is set create it
                path.createsshkeyrootpath()
                // Create keys
                argumentsssh = ArgumentsSsh(remote: nil, sshkeypathandidentityfile: (path.fullpathsshkeys ?? "") +
                    "/" + (path.identityfile ?? ""))
                arguments = argumentsssh?.argumentscreatekey()
                command = argumentsssh?.getCommand()
                executesshcreatekeys()
                return true
            }
        } catch let e {
            let error = e
            path.propogateerror(error: error)
            return false
        }
        return false
    }

    // Check if rsa pub key exists
    func islocalpublicrsakeypresent() throws -> Bool {
        guard keyFileStrings != nil else { return false }
        guard keyFileStrings?.filter({ $0.contains(self.path.identityfile ?? "") }).count ?? 0 > 0 else { return false }
        guard keyFileStrings?.filter({ $0.contains((self.path.identityfile ?? "") + ".pub") }).count ?? 0 > 0 else {
            throw SshError.sshkeys
        }
        rsaStringPath = keyFileStrings?.filter { $0.contains((self.path.identityfile ?? "") + ".pub") }[0]
        guard rsaStringPath?.count ?? 0 > 0 else { return false }
        throw SshError.sshkeys
    }

    nonisolated
    func validatepublickeypresent() -> Bool {
        guard keyFileStrings != nil else { return false }
        guard keyFileStrings?.filter({ $0.contains(self.path.identityfile ?? "") }).count ?? 0 > 0 else { return false }
        guard keyFileStrings?.filter({ $0.contains((self.path.identityfile ?? "") + ".pub") }).count ?? 0 > 0 else {
            return true
        }
        rsaStringPath = keyFileStrings?.filter { $0.contains((self.path.identityfile ?? "") + ".pub") }[0]
        guard rsaStringPath?.count ?? 0 > 0 else { return false }
        return true
    }

    // Secure copy of public key from local to remote catalog
    func copylocalpubrsakeyfile(remote: UniqueserversandLogins?) -> String {
        let argumentsssh = ArgumentsSsh(remote: remote, sshkeypathandidentityfile: (path.fullpathsshkeys ?? "") +
            "/" + (path.identityfile ?? ""))
        return argumentsssh.argumentssshcopyid() ?? ""
    }

    // Check for remote pub keys
    func verifyremotekey(remote: UniqueserversandLogins?) -> String {
        let argumentsssh = ArgumentsSsh(remote: remote, sshkeypathandidentityfile: (path.fullpathsshkeys ?? "") +
            "/" + (path.identityfile ?? ""))
        return argumentsssh.argumentscheckremotepubkey() ?? ""
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
        _ = Logfile(TrimTwo(data ?? []).trimmeddata, error: false)
    }

    init() {
        keyFileStrings = path.getfullpathsshkeys()
    }
}
