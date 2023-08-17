//
//  ObservableSSH.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 14/03/2021.
//

import Foundation
import Observation

@Observable
final class ObservableSSH {
    // Global SSH parameters
    // Have to convert String -> Int before saving
    // Set the current value as placeholder text
    var sshportnumber: String = ""
    // SSH keypath and identityfile, the settings View is picking up the current value
    // Set the current value as placeholder text
    var sshkeypathandidentityfile: String = ""
    // alert about error
    var error: Error = InputError.noerror
    var alerterror: Bool = false

    // SSH identityfile
    private func checksshkeypathbeforesaving(_ keypath: String) throws -> Bool {
        if keypath.first != "~" { throw SshError.noslash }
        let tempsshkeypath = keypath
        let sshkeypathandidentityfilesplit = tempsshkeypath.split(separator: "/")
        guard sshkeypathandidentityfilesplit.count > 2 else { throw SshError.noslash }
        guard sshkeypathandidentityfilesplit[1].count > 1 else { throw SshError.notvalidpath }
        guard sshkeypathandidentityfilesplit[2].count > 1 else { throw SshError.notvalidpath }
        return true
    }

    func sshkeypath(_ keypath: String) {
        // If keypath is empty set it to nil, e.g default value
        guard keypath.isEmpty == false else {
            SharedReference.shared.sshkeypathandidentityfile = nil
            return
        }
        do {
            let verified = try checksshkeypathbeforesaving(keypath)
            if verified {
                SharedReference.shared.sshkeypathandidentityfile = keypath
                // Save port number also
                if let port = Int(sshportnumber) {
                    SharedReference.shared.sshport = port
                }
            }
        } catch let e {
            error = e
            alerterror = true
        }
    }

    // SSH port number
    private func checksshport(_ port: String) throws -> Bool {
        guard port.isEmpty == false else { return false }
        if Int(port) != nil {
            return true
        } else {
            throw InputError.notvalidInt
        }
    }

    func sshport(_ port: String) {
        // if port is empty set it to nil, e.g. default value
        guard port.isEmpty == false else {
            SharedReference.shared.sshport = nil
            return
        }
        do {
            let verified = try checksshport(port)
            if verified {
                SharedReference.shared.sshport = Int(port)
            }
        } catch let e {
            error = e
            alerterror = true
        }
    }
}

enum InputError: LocalizedError {
    case notvalidDouble
    case notvalidInt
    case noerror

    var errorDescription: String? {
        switch self {
        case .notvalidDouble:
            return "Not a valid number (Double)"
        case .notvalidInt:
            return "Not a valid number (Int)"
        case .noerror:
            return ""
        }
    }
}
