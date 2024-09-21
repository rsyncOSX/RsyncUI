//
//  ObservableParametersDefault.swift
//
//  Created by Thomas Evensen on 18/08/2021.
//

import Foundation
import Observation

@Observable @MainActor
final class ObservableParametersDefault {
    // Selected configuration
    var configuration: SynchronizeConfiguration?
    // Local SSH parameters
    // Have to convert String -> Int before saving
    // Set the current value as placeholder text
    var sshport: String = ""
    // SSH keypath and identityfile, the settings View is picking up the current value
    // Set the current value as placeholder text
    var sshkeypathandidentityfile: String = ""
    // Remove parameters
    var removecompress: Bool = false
    var removedelete: Bool = false
    var daemon: Bool = false

    func setvalues(_ config: SynchronizeConfiguration?) {
        if let config {
            configuration = config
            // --compress parameter3
            // --delete parameter4
            if (configuration?.parameter3 ?? "").isEmpty { removecompress = true } else { removecompress = false }
            if (configuration?.parameter4 ?? "").isEmpty { removedelete = true } else { removedelete = false }
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

    // Return the updated configuration
    func updatersyncparameters() -> SynchronizeConfiguration? {
        if var configuration {
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
        removecompress = false
        removedelete = false
        daemon = false
    }
}
