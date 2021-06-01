//
//  ObserveableParametersRsync.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 20/03/2021.
//
// swiftlint:disable function_body_length

import Combine
import Foundation

final class ObserveableParametersRsync: ObservableObject {
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
    // Remove parameters
    @Published var removessh: Bool = false
    @Published var removecompress: Bool = false
    @Published var removedelete: Bool = false
    // Buttons
    @Published var suffixlinux: Bool = false
    @Published var suffixfreebsd: Bool = false
    @Published var backup: Bool = false
    @Published var daemon: Bool = false
    // Combine
    var subscriptions = Set<AnyCancellable>()
    // parameters for delete
    var parameter3: String?
    var parameter4: String?
    var parameter5: String?
    var rsyncdaemon: Int?

    init() {
        $inputchangedbyuser
            .sink { _ in
            }.store(in: &subscriptions)
        $parameter8
            .debounce(for: .seconds(1), scheduler: globalMainQueue)
            .sink { [unowned self] _ in
                isDirty = inputchangedbyuser
            }.store(in: &subscriptions)
        $parameter9
            .debounce(for: .seconds(1), scheduler: globalMainQueue)
            .sink { [unowned self] _ in
                isDirty = inputchangedbyuser
            }.store(in: &subscriptions)
        $parameter10
            .debounce(for: .seconds(1), scheduler: globalMainQueue)
            .sink { [unowned self] _ in
                isDirty = inputchangedbyuser
            }.store(in: &subscriptions)
        $parameter11
            .debounce(for: .seconds(1), scheduler: globalMainQueue)
            .sink { [unowned self] _ in
                isDirty = inputchangedbyuser
            }.store(in: &subscriptions)
        $parameter12
            .debounce(for: .seconds(1), scheduler: globalMainQueue)
            .sink { [unowned self] _ in
                isDirty = inputchangedbyuser
            }.store(in: &subscriptions)
        $parameter13
            .debounce(for: .seconds(1), scheduler: globalMainQueue)
            .sink { [unowned self] _ in
                isDirty = inputchangedbyuser
            }.store(in: &subscriptions)
        $parameter14
            .debounce(for: .seconds(1), scheduler: globalMainQueue)
            .sink { [unowned self] _ in
                isDirty = inputchangedbyuser
            }.store(in: &subscriptions)
        $configuration
            .sink { [unowned self] config in
                if let config = config { setvalues(config) }
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
        $removessh
            .debounce(for: .milliseconds(500), scheduler: globalMainQueue)
            .sink { [unowned self] ssh in
                deletessh(ssh)
            }.store(in: &subscriptions)
        $removedelete
            .debounce(for: .milliseconds(500), scheduler: globalMainQueue)
            .sink { [unowned self] delete in
                deletedelete(delete)
            }.store(in: &subscriptions)
        $removecompress
            .debounce(for: .milliseconds(500), scheduler: globalMainQueue)
            .sink { [unowned self] compress in
                deletecompress(compress)
            }.store(in: &subscriptions)
        $suffixlinux
            .debounce(for: .milliseconds(500), scheduler: globalMainQueue)
            .sink { [unowned self] _ in
                setsuffixlinux()
            }.store(in: &subscriptions)
        $suffixfreebsd
            .debounce(for: .milliseconds(500), scheduler: globalMainQueue)
            .sink { [unowned self] _ in
                setsuffixfreebsd()
            }.store(in: &subscriptions)
        $daemon
            .debounce(for: .milliseconds(500), scheduler: globalMainQueue)
            .sink { [unowned self] _ in
                setrsyncdaemon()
            }.store(in: &subscriptions)
        $backup
            .debounce(for: .milliseconds(500), scheduler: globalMainQueue)
            .sink { [unowned self] _ in
                setbackup()
            }.store(in: &subscriptions)
    }
}

extension ObserveableParametersRsync {
    func setvalues(_ config: Configuration) {
        isDirty = false
        inputchangedbyuser = false
        parameter8 = config.parameter8 ?? ""
        parameter9 = config.parameter9 ?? ""
        parameter10 = config.parameter10 ?? ""
        parameter11 = config.parameter11 ?? ""
        parameter12 = config.parameter12 ?? ""
        parameter13 = config.parameter13 ?? ""
        parameter14 = config.parameter14 ?? ""
        if let configsshport = config.sshport {
            sshport = String(configsshport)
        } else {
            sshport = ""
        }
        sshkeypathandidentityfile = config.sshkeypathandidentityfile ?? ""
        parameter3 = config.parameter3
        parameter4 = config.parameter4
        parameter5 = config.parameter5
        // set delete toggles
        if (parameter3 ?? "").isEmpty { removecompress = true } else { removecompress = false }
        if (parameter4 ?? "").isEmpty { removedelete = true } else { removedelete = false }
        if (parameter5 ?? "").isEmpty { removessh = true } else { removessh = false }
        // Rsync daemon
        rsyncdaemon = config.rsyncdaemon
    }

    // parameter5 -e ssh
    private func deletessh(_ delete: Bool) {
        guard configuration != nil else { return }
        guard inputchangedbyuser == true else { return }
        if delete {
            parameter5 = nil
        } else {
            parameter5 = "-e"
        }
        isDirty = true
    }

    // parameter4 --delete
    private func deletedelete(_ delete: Bool) {
        guard configuration != nil else { return }
        guard inputchangedbyuser == true else { return }
        if delete {
            parameter4 = nil
        } else {
            parameter4 = "--delete"
        }
        isDirty = true
    }

    // parameter3 --compress
    private func deletecompress(_ delete: Bool) {
        guard configuration != nil else { return }
        guard inputchangedbyuser == true else { return }
        if delete {
            parameter3 = nil
        } else {
            parameter3 = "--compress"
        }
        isDirty = true
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

    func sshkeypathandidentiyfile(_ keypath: String) {
        guard configuration != nil else { return }
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
            propogateerror(error: error)
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
        guard configuration != nil else { return }
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
            propogateerror(error: error)
        }
    }

    func setbackup() {
        guard inputchangedbyuser == true else { return }
        if let config = configuration {
            let localcatalog = config.localCatalog
            let localcatalogparts = (localcatalog as AnyObject).components(separatedBy: "/")
            parameter12 = RsyncArguments().backupstrings[0]
            guard localcatalogparts.count > 2 else { return }
            if config.offsiteCatalog.contains("~") {
                parameter13 = "~/backup" + "_" + localcatalogparts[localcatalogparts.count - 2]
            } else {
                parameter13 = "../backup" + "_" + localcatalogparts[localcatalogparts.count - 2]
            }
            isDirty = true
        }
    }

    func setsuffixlinux() {
        guard inputchangedbyuser == true else { return }
        guard configuration != nil else { return }
        parameter14 = RsyncArguments().suffixstringlinux
        isDirty = true
    }

    func setsuffixfreebsd() {
        guard inputchangedbyuser == true else { return }
        guard configuration != nil else { return }
        parameter14 = RsyncArguments().suffixstringfreebsd
        isDirty = true
    }

    func setrsyncdaemon() {
        guard inputchangedbyuser == true else { return }
        guard configuration != nil else { return }
        // either reverse or set
        if let daemon = rsyncdaemon {
            if daemon == 1 {
                rsyncdaemon = nil
                parameter5 = "-e"
            } else {
                rsyncdaemon = 1
                parameter5 = ""
            }

        } else {
            rsyncdaemon = 1
            parameter5 = ""
        }
        isDirty = true
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
