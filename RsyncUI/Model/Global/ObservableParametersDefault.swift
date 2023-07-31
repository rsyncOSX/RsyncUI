//
//  ObserveableParametersDefault.swift
//  ObserveableParametersDefault
//
//  Created by Thomas Evensen on 18/08/2021.
//

import Combine
import Foundation

@MainActor
final class ObservableParametersDefault: ObservableObject {
    // Selected configuration
    @Published var configuration: Configuration?
    // Local SSH parameters
    // Have to convert String -> Int before saving
    // Set the current value as placeholder text
    @Published var sshport: String = ""
    // SSH keypath and identityfile, the settings View is picking up the current value
    // Set the current value as placeholder text
    @Published var sshkeypathandidentityfile: String = ""
    // Remove parameters
    @Published var removessh: Bool = false
    @Published var removecompress: Bool = false
    @Published var removedelete: Bool = false
    @Published var daemon: Bool = false
    // Alerts
    @Published var alerterror: Bool = false
    @Published var error: Error = Validatedpath.noerror

    // Combine
    var subscriptions = Set<AnyCancellable>()

    init() {
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
            .sink { [unowned self] removessh in
                deletessh(removessh)
            }.store(in: &subscriptions)
        $removedelete
            .sink { [unowned self] removedelete in
                deletedelete(removedelete)
            }.store(in: &subscriptions)
        $removecompress
            .sink { [unowned self] removecompress in
                deletecompress(removecompress)
            }.store(in: &subscriptions)
        $daemon
            .sink { [unowned self] setdaemon in
                setrsyncdaemon(setdaemon)
            }.store(in: &subscriptions)
    }
}

extension ObservableParametersDefault {
    func setvalues(_ config: Configuration?) {
        if let config = config {
            configuration = config
            // --compress parameter3
            // --delete parameter4
            // -e (parameter 6 = "ssh"
            // set delete toggles
            if (configuration?.parameter3 ?? "").isEmpty { removecompress = true } else { removecompress = false }
            if (configuration?.parameter4 ?? "").isEmpty { removedelete = true } else { removedelete = false }
            if (configuration?.parameter5 ?? "").isEmpty { removessh = true } else { removessh = false }
            // Rsync daemon
            // configuration?.rsyncdaemon = config.rsyncdaemon
            if (configuration?.rsyncdaemon ?? 0) == 0 { daemon = false } else { daemon = true }
            // ssh port and keypart
            if sshport.isEmpty == false {
                configuration?.sshport = Int(sshport)
            } else {
                sshport = String(configuration?.sshport ?? -1)
                if sshport == "-1" {
                    sshport = ""
                }
            }
            if sshkeypathandidentityfile.isEmpty == false {
                configuration?.sshkeypathandidentityfile = sshkeypathandidentityfile
            } else {
                sshkeypathandidentityfile = configuration?.sshkeypathandidentityfile ?? ""
            }
        } else {
            reset()
        }
    }

    // parameter5 -e ssh
    private func deletessh(_ delete: Bool) {
        guard configuration != nil else { return }
        if delete {
            configuration?.parameter5 = ""
        } else {
            configuration?.parameter5 = "-e"
        }
    }

    // parameter4 --delete
    private func deletedelete(_ delete: Bool) {
        guard configuration != nil else { return }
        if delete {
            configuration?.parameter4 = ""
        } else {
            configuration?.parameter4 = "--delete"
        }
    }

    // parameter3 --compress
    private func deletecompress(_ delete: Bool) {
        guard configuration != nil else { return }
        if delete {
            configuration?.parameter3 = ""
        } else {
            configuration?.parameter3 = "--compress"
        }
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
        // If keypath is empty set it to nil, e.g default value
        guard keypath.isEmpty == false else {
            configuration?.sshkeypathandidentityfile = nil
            return
        }
        do {
            let verified = try checksshkeypathbeforesaving(keypath)
            if verified {
                configuration?.sshkeypathandidentityfile = keypath
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
        guard configuration != nil else { return }
        // if port is empty set it to nil, e.g. default value
        guard port.isEmpty == false else {
            configuration?.sshport = nil
            return
        }
        do {
            let verified = try checksshport(port)
            if verified {
                configuration?.sshport = Int(port)
            }
        } catch let e {
            error = e
            alerterror = true
        }
    }

    func setrsyncdaemon(_ setdaemon: Bool) {
        guard configuration != nil else { return }
        if setdaemon {
            configuration?.rsyncdaemon = 1
            configuration?.parameter5 = ""
        } else {
            configuration?.rsyncdaemon = nil
            configuration?.parameter5 = "-e"
        }
    }

    // Return the updated configuration
    func updatersyncparameters() -> Configuration? {
        if var configuration = configuration {
            if sshport.isEmpty {
                configuration.sshport = nil
            } else {
                configuration.sshport = Int(sshport)
            }
            if sshkeypathandidentityfile.isEmpty {
                configuration.sshkeypathandidentityfile = nil
            } else {
                configuration.sshkeypathandidentityfile = sshkeypathandidentityfile
            }
            return configuration
        }
        return nil
    }

    func reset() {
        configuration = nil
        sshport = ""
        sshkeypathandidentityfile = ""
        removessh = false
        removecompress = false
        removedelete = false
        daemon = false
    }
}
