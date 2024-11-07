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

    // MaxhiddenID is used when new configurations are added.
    var maxhiddenID: Int {
        if let configs = configurations {
            var setofhiddenIDs = Set<Int>()
            _ = configs.map { record in
                setofhiddenIDs.insert(record.hiddenID)
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
                configurations?[index].snapshotnum = config.snapshotnum
            }
            WriteSynchronizeConfigurationJSON(localeprofile, configurations)
        }
    }
    
    func deleteconfigurations(uuids: Set<UUID>) {
        var indexset = IndexSet()
        if let configurations = configurations {
            _ = configurations.map({ configuration in
                if let index = configurations.firstIndex(of: configuration)
                {
                    if uuids.contains(configuration.id) {
                        indexset.insert(index)
                    }
                }
            })
        }
        // Remove all marked configurations in one go by IndexSet
        configurations?.remove(atOffsets: indexset)
        // No need for deleting the logs, only logrecords with valid hiddenIDs are loaded
        WriteSynchronizeConfigurationJSON(localeprofile, configurations)
    }

    // Add new configurations
    func addconfiguration(_ config: SynchronizeConfiguration) -> Bool {
        let beforecount = (configurations?.count ?? 0)
        var newconfig: SynchronizeConfiguration = config
        newconfig.hiddenID = maxhiddenID + 1
        configurations?.append(newconfig)
        let aftercount = (configurations?.count ?? 0)
        WriteSynchronizeConfigurationJSON(localeprofile, configurations)
        if aftercount > beforecount {
            return true
        } else {
            return false
        }
    }

    func addimportconfigurations(_ importconfigurations: [SynchronizeConfiguration]) {
        if importconfigurations.count > 0, var configurations {
            configurations += importconfigurations
            WriteSynchronizeConfigurationJSON(localeprofile, configurations)
        }
    }

    // Write Copy and Paste tasks
    func writecopyandpastetask(_ copyandpastetasks: [SynchronizeConfiguration]?) -> [SynchronizeConfiguration]? {
        if let copyandpastetasks, var configurations {
            configurations += copyandpastetasks
            WriteSynchronizeConfigurationJSON(localeprofile, configurations)
            return configurations
        }
        return nil
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
