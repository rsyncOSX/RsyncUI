//
//  ObservableParametersRsync.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 20/03/2021.
//

import Foundation
import Observation
import SSHCreateKey

@Observable @MainActor
final class ObservableParametersRsync {
    /// Set the current value as placeholder text
    var sshport: String = ""
    /// SSH keypath and identityfile, the settings View is picking up the current value
    /// Set the current value as placeholder text
    var sshkeypathandidentityfile: String = ""
    // Rsync parameters
    var parameter8: String = ""
    var parameter9: String = ""
    var parameter10: String = ""
    var parameter11: String = ""
    var parameter12: String = ""
    var parameter13: String = ""
    var parameter14: String = ""
    // Selected configuration
    var configuration: SynchronizeConfiguration?
    var sshcreatekey: SSHCreateKey?
    /// Add parameters
    var adddelete: Bool = false
    /// Argument slots shown in the view, a shown slot stays while it is edited
    private var shownArgumentSlots = Set<Int>()

    func setvalues(_ config: SynchronizeConfiguration?) {
        if let config {
            configuration = config
            parameter8 = configuration?.parameter8 ?? ""
            parameter9 = configuration?.parameter9 ?? ""
            parameter10 = configuration?.parameter10 ?? ""
            parameter11 = configuration?.parameter11 ?? ""
            parameter12 = configuration?.parameter12 ?? ""
            parameter13 = configuration?.parameter13 ?? ""
            parameter14 = configuration?.parameter14 ?? ""
            if let configsshport = configuration?.sshport,
               configsshport != -1 {
                sshport = String(configsshport)
            } else {
                sshport = ""
            }
            if let configurationsshcreatekey = configuration?.sshkeypathandidentityfile {
                sshkeypathandidentityfile = configurationsshcreatekey
            } else {
                sshkeypathandidentityfile = ""
            }
            showUsedArgumentSlots()
            // --delete parameter4
            if configuration?.parameter4 == nil {
                adddelete = false
            } else {
                adddelete = true
            }
        } else {
            reset()
        }
    }

    /// Slots for user selected arguments
    private static let parameterSlots: [ReferenceWritableKeyPath<ObservableParametersRsync, String>] = [
        \.parameter8, \.parameter9, \.parameter10, \.parameter11, \.parameter12, \.parameter13, \.parameter14
    ]
    /// The order in which the backup arguments prefer the slots
    private static let backupSlots = Array(parameterSlots[4...] + parameterSlots[..<4])

    var visibleArgumentSlots: [Int] {
        Self.parameterSlots.indices.filter { shownArgumentSlots.contains($0) || !argument(in: $0).isEmpty }
    }

    var canAddArgument: Bool {
        visibleArgumentSlots.count < Self.parameterSlots.count
    }

    func argument(in slot: Int) -> String {
        self[keyPath: Self.parameterSlots[slot]]
    }

    func setArgument(_ argument: String, in slot: Int) {
        self[keyPath: Self.parameterSlots[slot]] = argument
    }

    /// Show the first slot not in use
    func addArgument() {
        let visible = visibleArgumentSlots
        if let slot = Self.parameterSlots.indices.first(where: { !visible.contains($0) }) {
            shownArgumentSlots.insert(slot)
        }
    }

    /// Show only the slots in use
    private func showUsedArgumentSlots() {
        shownArgumentSlots = Set(Self.parameterSlots.indices.filter { !argument(in: $0).isEmpty })
    }

    private static func isBackupArgument(_ argument: String) -> Bool {
        let name = argument.prefix { $0 != "=" }
        return name == "-b" || name == "--backup" || name == "--backup-dir"
    }

    /// Read from the arguments, so the toggle always shows what rsync will do.
    var backupIsEnabled: Bool {
        Self.parameterSlots.contains { Self.isBackupArgument(self[keyPath: $0]) }
    }

    /// Add or remove the backup arguments, leaving all other arguments in place.
    func setbackup(_ enabled: Bool) {
        guard let configuration, enabled != backupIsEnabled else { return }

        guard enabled else {
            for slot in Self.parameterSlots where Self.isBackupArgument(self[keyPath: slot]) {
                self[keyPath: slot] = ""
            }
            showUsedArgumentSlots()
            return
        }

        let backupstrings = ArgumentsRsyncUserSelect().backupstrings
        var arguments = [backupstrings[0]]
        let localcatalogparts = configuration.localCatalog.components(separatedBy: "/")
        if localcatalogparts.count > 2 {
            let backupdir = configuration.offsiteCatalog.contains("~") ? backupstrings[1] : backupstrings[2]
            arguments.append(backupdir + "_" + localcatalogparts[localcatalogparts.count - 2])
        }

        let freeSlots = Self.backupSlots.filter { self[keyPath: $0].isEmpty }
        guard freeSlots.count >= arguments.count else { return }
        for (slot, argument) in zip(freeSlots, arguments) {
            self[keyPath: slot] = argument
        }
        showUsedArgumentSlots()
    }

    /// Return the updated configuration
    func updatersyncparameters() -> SynchronizeConfiguration? {
        if var configuration {
            if parameter8.isEmpty {
                configuration.parameter8 = nil
            } else {
                configuration.parameter8 = parameter8
            }
            if parameter9.isEmpty {
                configuration.parameter9 = nil
            } else {
                configuration.parameter9 = parameter9
            }
            if parameter10.isEmpty {
                configuration.parameter10 = nil
            } else {
                configuration.parameter10 = parameter10
            }
            if parameter11.isEmpty {
                configuration.parameter11 = nil
            } else {
                configuration.parameter11 = parameter11
            }
            if parameter12.isEmpty {
                configuration.parameter12 = nil
            } else {
                configuration.parameter12 = parameter12
            }
            if parameter13.isEmpty {
                configuration.parameter13 = nil
            } else {
                configuration.parameter13 = parameter13
            }
            if parameter14.isEmpty {
                configuration.parameter14 = nil
            } else {
                configuration.parameter14 = parameter14
            }
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
        parameter8 = ""
        parameter9 = ""
        parameter10 = ""
        parameter11 = ""
        parameter12 = ""
        parameter13 = ""
        parameter14 = ""
        sshport = ""
        sshkeypathandidentityfile = ""
        adddelete = false
        showUsedArgumentSlots()
    }

    /// parameter4 --delete
    func adddelete(_ adddelete: Bool) {
        guard configuration != nil else { return }
        if adddelete {
            configuration?.parameter4 = "--delete"
        } else {
            configuration?.parameter4 = nil
        }
    }

    init() {
        let sshport = SharedReference.shared.sshport
        let sshkeypathandidentityfile = SharedReference.shared.sshkeypathandidentityfile

        if let port = sshport, let keypath = sshkeypathandidentityfile {
            // Both values are not nil
            sshcreatekey = SSHCreateKey(sharedSSHPort: String(port),
                                        sharedSSHKeyPathAndIdentityFile: keypath)
        } else if let port = sshport {
            // Only port is not nil
            sshcreatekey = SSHCreateKey(sharedSSHPort: String(port),
                                        sharedSSHKeyPathAndIdentityFile: nil)
        } else if let keypath = sshkeypathandidentityfile {
            // Only keypath is not nil
            sshcreatekey = SSHCreateKey(sharedSSHPort: nil,
                                        sharedSSHKeyPathAndIdentityFile: keypath)
        }
        // If both are nil, sshcreatekey remains nil
    }
}
