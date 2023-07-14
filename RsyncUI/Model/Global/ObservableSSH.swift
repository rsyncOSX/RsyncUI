//
//  ObservableReferenceSSH.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 14/03/2021.
//

import Combine
import Foundation
import Observation

@available(macOS 14, *)
@Observable
final class ObservableSSH: SSH {
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

    func errorisdiscovered(_ e: Error) {
        error = e
        alerterror = true
    }
}

final class ObservableSSH_pre: ObservableObject, SSH {
    // Global SSH parameters
    // Have to convert String -> Int before saving
    // Set the current value as placeholder text
    @Published var sshport: String = ""
    // SSH keypath and identityfile, the settings View is picking up the current value
    // Set the current value as placeholder text
    @Published var sshkeypathandidentityfile: String = ""
    // Alerts
    @Published var alerterror: Bool = false
    @Published var error: Error = Validatedpath.noerror

    // Combine
    var subscriptions = Set<AnyCancellable>()

    init() {
        $sshkeypathandidentityfile
            .debounce(for: .seconds(1), scheduler: globalMainQueue)
            .sink { [unowned self] identityfile in
                sshkeypath(identityfile, sshport)
            }.store(in: &subscriptions)
        $sshport
            .debounce(for: .seconds(1), scheduler: globalMainQueue)
            .sink { [unowned self] port in
                sshport(port)
            }.store(in: &subscriptions)
    }

    func errorisdiscovered(_ e: Error) {
        error = e
        alerterror = true
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

protocol SSH: AnyObject {
    func sshport(_ port: String)
    func sshkeypath(_ keypath: String, _ sshportnumber: String)
    func errorisdiscovered(_ e: Error)
}

extension SSH {
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

    func sshkeypath(_ keypath: String, _ sshportnumber: String) {
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
            // error = e
            // alerterror = true
            errorisdiscovered(e)
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
            // error = e
            // alerterror = true
            errorisdiscovered(e)
        }
    }
}
