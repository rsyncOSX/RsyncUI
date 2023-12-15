//
//  ObservableParametersDefault.swift
//
//  Created by Thomas Evensen on 18/08/2021.
//

import Foundation
import Observation

@Observable
final class ObservableParametersDefault {
    // Selected configuration
    var configuration: Configuration?
    // Local SSH parameters
    // Have to convert String -> Int before saving
    // Set the current value as placeholder text
    var sshport: String = ""
    // SSH keypath and identityfile, the settings View is picking up the current value
    // Set the current value as placeholder text
    var sshkeypathandidentityfile: String = ""
    // Remove parameters
    var removessh: Bool = false
    var removecompress: Bool = false
    var removedelete: Bool = false
    var daemon: Bool = false
    // Alerts
    var alerterror: Bool = false
    var error: Error = Validatedpath.noerror

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
            sshport = String(configuration?.sshport ?? -1)
            if sshport == "-1" { sshport = "" }
            sshkeypathandidentityfile = configuration?.sshkeypathandidentityfile ?? ""
        } else {
            reset()
        }
    }

    // parameter5 -e ssh
    func deletessh(_ delete: Bool) {
        guard configuration != nil else { return }
        if delete {
            configuration?.parameter5 = ""
        } else {
            configuration?.parameter5 = "-e"
        }
    }

    // parameter4 --delete
    func deletedelete(_ delete: Bool) {
        guard configuration != nil else { return }
        if delete {
            configuration?.parameter4 = ""
        } else {
            configuration?.parameter4 = "--delete"
        }
    }

    // parameter3 --compress
    func deletecompress(_ delete: Bool) {
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

    func sshkeypath(_ keypath: String) {
        guard configuration != nil else { return }
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

    func setsshport(_ port: String) {
        guard configuration != nil else { return }
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
