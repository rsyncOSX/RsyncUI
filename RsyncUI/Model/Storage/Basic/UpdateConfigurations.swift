//
//  UpdateConfigurations.swift
//
//
// REFACTOR

import Foundation
import OSLog

@MainActor
final class UpdateConfigurations {
    var configurations: [SynchronizeConfiguration]?
    private var localeprofile: String?

    // MaxhiddenID is used when new configurations are added.
    var maxhiddenID: Int {
        if let configs = configurations {
            var setofhiddenIDs = Set<Int>()
            for item in configs {
                setofhiddenIDs.insert(item.hiddenID)
            }
            return setofhiddenIDs.max() ?? 0
        }
        return 0
    }

    private func persistConfigurations() {
        guard let configurations else { return }
        guard validateConfigurations(configurations) else {
            Logger.process.error("UpdateConfigurations: validation failed, refused to persist")
            return
        }
        WriteSynchronizeConfigurationJSON(localeprofile, configurations)
    }

    private func validateConfigurations(_ configurations: [SynchronizeConfiguration]) -> Bool {
        let hiddenIDs = configurations.map(\.hiddenID)
        guard hiddenIDs.count == Set(hiddenIDs).count else { return false }

        let requiredFieldsOK = configurations.allSatisfy { config in
            config.hiddenID >= 0 &&
                config.task.isEmpty == false &&
                config.localCatalog.isEmpty == false &&
                config.offsiteCatalog.isEmpty == false
        }

        let remoteFieldsOK = configurations.allSatisfy { config in
            if config.offsiteServer.isEmpty {
                return true
            }
            return config.offsiteUsername.isEmpty == false
        }

        return requiredFieldsOK && remoteFieldsOK
    }

    private func configurationsWithNewHiddenIDs(_ newConfigs: [SynchronizeConfiguration]) -> [SynchronizeConfiguration] {
        var nextHiddenID = maxhiddenID + 1
        return newConfigs.map { config in
            var updatedConfig = config
            updatedConfig.id = UUID()
            updatedConfig.hiddenID = nextHiddenID
            nextHiddenID += 1
            return updatedConfig
        }
    }

    // Function is updating Configurations in memory (by record) and
    // then saves updated Configurations from memory to persistent store
    func updateConfiguration(_ config: SynchronizeConfiguration, _ parameters: Bool) {
        if let index = configurations?.firstIndex(where: { $0.hiddenID == config.hiddenID }) {
            if parameters {
                // Updated parameters only, keep all other
                // keep last run date
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
            persistConfigurations()
        }
    }

    // Delete by IndexSet
    func deleteconfigurations(_ uuids: Set<UUID>) {
        var indexset = IndexSet()
        if let configurations {
            for configuration in configurations {
                if let index = configurations.firstIndex(of: configuration) {
                    if uuids.contains(configuration.id) {
                        indexset.insert(index)
                    }
                }
            }
        }
        // Remove all marked configurations in one go by IndexSet
        configurations?.remove(atOffsets: indexset)
        // No need for deleting the logs, only logrecords with valid hiddenIDs are loaded
        persistConfigurations()
    }

    // Add new configurations
    func addConfiguration(_ config: SynchronizeConfiguration) -> Bool {
        if configurations == nil {
            configurations = [SynchronizeConfiguration]()
        }
        let beforecount = (configurations?.count ?? 0)
        var newconfig: SynchronizeConfiguration = config
        newconfig.id = UUID()
        newconfig.hiddenID = maxhiddenID + 1
        configurations?.append(newconfig)
        let aftercount = (configurations?.count ?? 0)
        persistConfigurations()
        if aftercount > beforecount {
            return true
        } else {
            return false
        }
    }

    // Write Import configurations
    func addImportConfigurations(_ importconfigurations: [SynchronizeConfiguration]) -> [SynchronizeConfiguration]? {
        guard importconfigurations.isEmpty == false else { return nil }
        if configurations == nil {
            configurations = [SynchronizeConfiguration]()
        }
        let reassigned = configurationsWithNewHiddenIDs(importconfigurations)
        configurations?.append(contentsOf: reassigned)
        persistConfigurations()
        return configurations
    }

    // Write Copy and Paste tasks
    func writeCopyAndPasteTask(_ copyandpastetasks: [SynchronizeConfiguration]?) -> [SynchronizeConfiguration]? {
        guard let copyandpastetasks, copyandpastetasks.isEmpty == false else { return nil }
        if configurations == nil {
            configurations = [SynchronizeConfiguration]()
        }
        let reassigned = configurationsWithNewHiddenIDs(copyandpastetasks)
        configurations?.append(contentsOf: reassigned)
        persistConfigurations()
        return configurations
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
