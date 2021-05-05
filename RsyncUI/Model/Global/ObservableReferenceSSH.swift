//
//  ObservableReferenceSSH.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 14/03/2021.
//

import Combine
import Foundation

final class ObservableReferenceSSH: ObservableObject {
    // When property is changed set isDirty = true
    @Published var isDirty: Bool = false
    // Global SSH parameters
    // Have to convert String -> Int before saving
    // Set the current value as placeholder text
    @Published var sshport: String = ""
    // SSH keypath and identityfile, the settings View is picking up the current value
    // Set the current value as placeholder text
    @Published var sshkeypathandidentityfile: String = ""
    // If local public sshkeys are present
    @Published var localsshkeys: Bool = SshKeys().validatepublickeypresent()
    // Value to check if input field is changed by user
    @Published var inputchangedbyuser: Bool = false
    // Combine
    var subscriptions = Set<AnyCancellable>()

    init() {
        $inputchangedbyuser
            .sink { _ in
            }.store(in: &subscriptions)
        $sshkeypathandidentityfile
            .debounce(for: .seconds(1), scheduler: globalMainQueue)
            .sink { [unowned self] identityfile in
                sshkeypathandidentiyfile(identityfile)
            }.store(in: &subscriptions)
        $sshport
            .debounce(for: .seconds(1), scheduler: globalMainQueue)
            .sink { [unowned self] port in
                sshport(port)
            }.store(in: &subscriptions)
    }
}

extension ObservableReferenceSSH {
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

    func sshkeypathandidentiyfile(_ keypath: String) {
        guard inputchangedbyuser == true else { return }
        // If keypath is empty set it to nil, e.g default value
        guard keypath.isEmpty == false else {
            SharedReference.shared.sshkeypathandidentityfile = nil
            isDirty = true
            return
        }
        do {
            let verified = try checksshkeypathbeforesaving(keypath)
            if verified {
                SharedReference.shared.sshkeypathandidentityfile = keypath
                // Save port number also
                if let port = Int(sshport) {
                    SharedReference.shared.sshport = port
                }
                isDirty = true
            }
        } catch let e {
            let error = e
            self.propogateerror(error: error)
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
        guard inputchangedbyuser == true else { return }
        // if port is empty set it to nil, e.g. default value
        guard port.isEmpty == false else {
            SharedReference.shared.sshport = nil
            isDirty = true
            return
        }
        do {
            let verified = try checksshport(port)
            if verified {
                SharedReference.shared.sshport = Int(port)
                // Save identityfile also
                SharedReference.shared.sshkeypathandidentityfile = sshkeypathandidentityfile
                isDirty = true
            }
        } catch let e {
            let error = e
            self.propogateerror(error: error)
        }
    }
}

extension ObservableReferenceSSH: PropogateError {
    func propogateerror(error: Error) {
        SharedReference.shared.errorobject?.propogateerror(error: error)
    }
}

enum InputError: LocalizedError {
    case notvalidDouble
    case notvalidInt

    var errorDescription: String? {
        switch self {
        case .notvalidDouble:
            return NSLocalizedString("Not a valid number (Double)", comment: "ssh error") + "..."
        case .notvalidInt:
            return NSLocalizedString("Not a valid number (Int)", comment: "ssh error") + "..."
        }
    }
}
