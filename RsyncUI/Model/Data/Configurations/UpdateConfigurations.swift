//
//  UpdateConfigurations.swift
//
//
// swiftlint:disable opening_brace

import Foundation

@MainActor
final class UpdateConfigurations {
    var configurations: [SynchronizeConfiguration]?
    private var localeprofile: String?

    // Variable computes max hiddenID used
    // MaxhiddenID is used when new configurations are added.
    var maxhiddenID: Int {
        // Reading Configurations from memory
        if let configs = configurations {
            var setofhiddenIDs = Set<Int>()
            // Fill set with existing hiddenIDS
            for i in 0 ..< configs.count {
                setofhiddenIDs.insert(configs[i].hiddenID)
            }
            return setofhiddenIDs.max() ?? 0
        }
        return 0
    }

    // Function is updating Configurations in memory (by record) and
    // then saves updated Configurations from memory to persistent store
    func updateconfiguration(_ config: SynchronizeConfiguration, _ parameters: Bool) {
        if let index = configurations?.firstIndex(where: { $0.hiddenID == config.hiddenID }) {
            if parameters {
                // Updated parameters only, keep all other
                // keep last run date
                configurations?[index].parameter1 = config.parameter1
                configurations?[index].parameter2 = config.parameter2
                configurations?[index].parameter3 = config.parameter3
                configurations?[index].parameter4 = config.parameter4
                configurations?[index].parameter5 = config.parameter5
                configurations?[index].parameter6 = config.parameter6
                configurations?[index].parameter8 = config.parameter8
                configurations?[index].parameter9 = config.parameter9
                configurations?[index].parameter10 = config.parameter10
                configurations?[index].parameter11 = config.parameter11
                configurations?[index].parameter12 = config.parameter12
                configurations?[index].parameter13 = config.parameter13
                configurations?[index].parameter14 = config.parameter14
                configurations?[index].sshport = config.sshport
                configurations?[index].sshkeypathandidentityfile = config.sshkeypathandidentityfile
                configurations?[index].rsyncdaemon = config.rsyncdaemon
            } else {
                // Updated all other data but parameters
                // keep last run date
                configurations?[index].localCatalog = config.localCatalog
                configurations?[index].offsiteCatalog = config.offsiteCatalog
                configurations?[index].offsiteServer = config.offsiteServer
                configurations?[index].offsiteUsername = config.offsiteUsername
                configurations?[index].backupID = config.backupID
                configurations?[index].snaplast = config.snaplast
                configurations?[index].snapdayoffweek = config.snapdayoffweek
            }
            WriteConfigurationJSON(localeprofile, configurations)
        }
    }

    func deleteconfigurations(uuids: Set<UUID>) {
        if let configs = configurations {
            var indexset = IndexSet()
            for i in 0 ..< uuids.count {
                if let index = configs.firstIndex(
                    where: { $0.id == uuids[uuids.index(uuids.startIndex, offsetBy: i)] })
                {
                    indexset.insert(index)
                }
            }
            configurations?.remove(atOffsets: indexset)
            // No need for deleting the logs, only valid hiddenIDs are
            // loaded next time configurations are read from
            // permanent store
            WriteConfigurationJSON(localeprofile, configurations)
        }
    }

    // Add new configurations
    func addconfiguration(_ config: SynchronizeConfiguration) -> Bool {
        let beforecount = (configurations?.count ?? 0)
        var newconfig: SynchronizeConfiguration = config
        newconfig.hiddenID = maxhiddenID + 1
        configurations?.append(newconfig)
        let aftercount = (configurations?.count ?? 0)
        WriteConfigurationJSON(localeprofile, configurations)
        if aftercount > beforecount {
            return true
        } else {
            return false
        }
    }

    func addimportconfigurations(_ importconfigurations: [SynchronizeConfiguration]) {
        for i in 0 ..< importconfigurations.count {
            configurations?.append(importconfigurations[i])
        }
        if importconfigurations.count > 0 {
            WriteConfigurationJSON(localeprofile, configurations)
        }
    }

    // Write Copy and Paste tasks
    func writecopyandpastetask(_ copyandpastetasks: [SynchronizeConfiguration]?) {
        if let copyandpastetasks = copyandpastetasks {
            for i in 0 ..< copyandpastetasks.count {
                configurations?.append(copyandpastetasks[i])
            }
        }
        WriteConfigurationJSON(localeprofile, configurations)
    }

    init(profile: String?, configurations: [SynchronizeConfiguration]?) {
        localeprofile = profile
        // Create new set of configurations
        if configurations == nil {
            self.configurations = [SynchronizeConfiguration]()
        } else {
            self.configurations = configurations
        }
    }
}

// swiftlint:enable opening_brace
