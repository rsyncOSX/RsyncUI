//
//  SshKeys.swift
//  RsyncOSX
//
//  Created by Thomas Evensen on 23.04.2017.
//  Copyright © 2017 Thomas Evensen. All rights reserved.
//
// swiftlint:disable line_length

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

@MainActor
final class SshKeys {
    var rsaStringPath: String?
    // Arrays listing all key files
    var keyFileStrings: [String]?
    var argumentsssh: ArgumentsSsh?
    var command: String?
    var arguments: [String]?
    // All paths for ssh
    let sshpath = SSHpath()

    // Create rsa keypair
    func createPublicPrivateRSAKeyPair() -> Bool {
        do {
            let present = try islocalpublicrsakeypresent()
            if present == false {
                // If new keypath is set create it
                sshpath.createsshkeyrootpath()
                // Create keys
                argumentsssh = ArgumentsSsh(remote: nil, sshkeypathandidentityfile: (sshpath.fullpathsshkeys ?? "") +
                    "/" + (sshpath.identityfile ?? ""))
                arguments = argumentsssh?.argumentscreatekey()
                command = argumentsssh?.getCommand()
                executesshcreatekeys()
                return true
            }
        } catch let e {
            let error = e
            sshpath.propogateerror(error: error)
            return false
        }
        return false
    }

    // Check if rsa pub key exists
    func islocalpublicrsakeypresent() throws -> Bool {
        guard keyFileStrings != nil else { return false }
        guard keyFileStrings?.filter({ $0.contains(self.sshpath.identityfile ?? "") }).count ?? 0 > 0 else { return false }
        guard keyFileStrings?.filter({ $0.contains((self.sshpath.identityfile ?? "") + ".pub") }).count ?? 0 > 0 else {
            throw SshError.sshkeys
        }
        rsaStringPath = keyFileStrings?.filter { $0.contains((self.sshpath.identityfile ?? "") + ".pub") }[0]
        guard rsaStringPath?.count ?? 0 > 0 else { return false }
        throw SshError.sshkeys
    }

    func validatepublickeypresent() -> Bool {
        guard keyFileStrings != nil else { return false }
        guard keyFileStrings?.filter({ $0.contains(self.sshpath.identityfile ?? "") }).count ?? 0 > 0 else { return false }
        guard keyFileStrings?.filter({ $0.contains((self.sshpath.identityfile ?? "") + ".pub") }).count ?? 0 > 0 else {
            return true
        }
        rsaStringPath = keyFileStrings?.filter { $0.contains((self.sshpath.identityfile ?? "") + ".pub") }[0]
        guard rsaStringPath?.count ?? 0 > 0 else { return false }
        return true
    }

    // Secure copy of public key from local to remote catalog
    func copylocalpubrsakeyfile(remote: UniqueserversandLogins?) -> String {
        let argumentsssh = ArgumentsSsh(remote: remote, sshkeypathandidentityfile: (sshpath.fullpathsshkeys ?? "") +
            "/" + (sshpath.identityfile ?? ""))
        return argumentsssh.argumentssshcopyid() ?? ""
    }

    // Check for remote pub keys
    func verifyremotekey(remote: UniqueserversandLogins?) -> String {
        let argumentsssh = ArgumentsSsh(remote: remote, sshkeypathandidentityfile: (sshpath.fullpathsshkeys ?? "") +
            "/" + (sshpath.identityfile ?? ""))
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
        keyFileStrings = sshpath.getfullpathsshkeys()
    }
}

// swiftlint:enable line_length
