//
//  ObserveableParametersRsync.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 20/03/2021.
//
// swiftlint:disable function_body_length

import Combine
import Foundation

class ObserveableParametersRsync: ObservableObject {
    // When property is changed set isDirty = true
    @Published var isDirty: Bool = false
    // Rsync parameters
    @Published var parameter8: String = ""
    @Published var parameter9: String = ""
    @Published var parameter10: String = ""
    @Published var parameter11: String = ""
    @Published var parameter12: String = ""
    @Published var parameter13: String = ""
    @Published var parameter14: String = ""
    // Selected configuration
    @Published var configuration: Configuration?
    // Local SSH parameters
    // Have to convert String -> Int before saving
    // Set the current value as placeholder text
    @Published var sshport: String = ""
    // SSH keypath and identityfile, the settings View is picking up the current value
    // Set the current value as placeholder text
    @Published var sshkeypathandidentityfile: String = ""
    // If local public sshkeys are present
    @Published var inputchangedbyuser: Bool = false
    // Combine
    var subscriptions = Set<AnyCancellable>()

    init() {
        $inputchangedbyuser
            .sink { _ in
            }.store(in: &subscriptions)
        $parameter8
            .debounce(for: .seconds(2), scheduler: globalMainQueue)
            .sink { [unowned self] parameter8 in
                validate(parameter8)
                isDirty = inputchangedbyuser
            }.store(in: &subscriptions)
        $parameter9
            .debounce(for: .seconds(2), scheduler: globalMainQueue)
            .sink { [unowned self] parameter9 in
                validate(parameter9)
                isDirty = inputchangedbyuser
            }.store(in: &subscriptions)
        $parameter10
            .debounce(for: .seconds(2), scheduler: globalMainQueue)
            .sink { [unowned self] parameter10 in
                validate(parameter10)
                isDirty = inputchangedbyuser
            }.store(in: &subscriptions)
        $parameter11
            .debounce(for: .seconds(2), scheduler: globalMainQueue)
            .sink { [unowned self] parameter11 in
                validate(parameter11)
                isDirty = inputchangedbyuser
            }.store(in: &subscriptions)
        $parameter12
            .debounce(for: .seconds(2), scheduler: globalMainQueue)
            .sink { [unowned self] parameter12 in
                validate(parameter12)
                isDirty = inputchangedbyuser
            }.store(in: &subscriptions)
        $parameter13
            .debounce(for: .seconds(2), scheduler: globalMainQueue)
            .sink { [unowned self] parameter13 in
                validate(parameter13)
                isDirty = inputchangedbyuser
            }.store(in: &subscriptions)
        $parameter14
            .debounce(for: .seconds(2), scheduler: globalMainQueue)
            .sink { [unowned self] parameter14 in
                validate(parameter14)
                isDirty = inputchangedbyuser
            }.store(in: &subscriptions)
        $configuration
            .sink { [unowned self] config in
                if let config = config {
                    setvalues(config)
                }
                isDirty = false
            }.store(in: &subscriptions)
        $sshkeypathandidentityfile
            .debounce(for: .seconds(2), scheduler: globalMainQueue)
            .sink { [unowned self] identityfile in
                sshkeypathandidentiyfile(identityfile)
            }.store(in: &subscriptions)
        $sshport
            .debounce(for: .seconds(2), scheduler: globalMainQueue)
            .sink { [unowned self] port in
                sshport(port)
            }.store(in: &subscriptions)
    }

    private func validate(_ parameter: String) {
        print(parameter)
    }

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

    private func setvalues(_ config: Configuration) {
        parameter8 = config.parameter8 ?? ""
        parameter9 = config.parameter9 ?? ""
        parameter10 = config.parameter10 ?? ""
        parameter11 = config.parameter11 ?? ""
        parameter12 = config.parameter12 ?? ""
        parameter13 = config.parameter13 ?? ""
        parameter14 = config.parameter14 ?? ""
        if let configsshport = config.sshport {
            sshport = String(configsshport)
        }
        sshkeypathandidentityfile = config.sshkeypathandidentityfile ?? ""
    }

    func sshkeypathandidentiyfile(_ keypath: String) {
        guard inputchangedbyuser == true else { return }
        // If keypath is empty set it to nil, e.g default value
        guard keypath.isEmpty == false else {
            configuration?.sshkeypathandidentityfile = nil
            isDirty = true
            return
        }
        do {
            let verified = try checksshkeypathbeforesaving(keypath)
            if verified {
                configuration?.sshkeypathandidentityfile = keypath
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
            configuration?.sshport = nil
            isDirty = true
            return
        }
        do {
            let verified = try checksshport(port)
            if verified {
                configuration?.sshport = Int(port)
                isDirty = true
            }
        } catch let e {
            let error = e
            self.propogateerror(error: error)
        }
    }
}

extension ObserveableParametersRsync: PropogateError {
    func propogateerror(error: Error) {
        SharedReference.shared.errorobject?.propogateerror(error: error)
    }
}

enum ParameterError: LocalizedError {
    case notvalid

    var errorDescription: String? {
        switch self {
        case .notvalid:
            return NSLocalizedString("Not a valid ", comment: "ssh error") + "..."
        }
    }
}
