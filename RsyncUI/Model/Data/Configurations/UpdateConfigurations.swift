//
//  Configurations.swift
//
//  The obect is the model for the Configurations but also acts as Controller when
//  the ViewControllers reads or updates data.
//
//  The object also holds various configurations for RsyncOSX and references to
//  some of the ViewControllers used in calls to delegate functions.
//
//  Created by Thomas Evensen on 08/02/16.
//  Copyright © 2016 Thomas Evensen. All rights reserved.
//
// swiftlint:disable opening_brace

import Foundation
import SwiftUI

class UpdateConfigurations {
    private var configurations: [Configuration]?
    private var localeprofile: String?

    // Variable computes max hiddenID used
    // MaxhiddenID is used when new configurations are added.
    var maxhiddenID: Int {
        // Reading Configurations from memory
        if let configurations = self.configurations {
            if configurations.count > 0 {
                _ = configurations.sorted { (config1, config2) -> Bool in
                    if config1.hiddenID > config2.hiddenID {
                        return true
                    } else {
                        return false
                    }
                }
                let index = configurations.count - 1
                return configurations[index].hiddenID
            }
        } else {
            return 0
        }
        return 0
    }

    // Function is updating Configurations in memory (by record) and
    // then saves updated Configurations from memory to persistent store
    func updateconfiguration(_ config: Configuration, _ parameters: Bool) {
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
            } else {
                // Updated all other data but parameters
                // keep last run date
                configurations?[index].localCatalog = config.localCatalog
                configurations?[index].offsiteCatalog = config.offsiteCatalog
                configurations?[index].offsiteServer = config.offsiteServer
                configurations?[index].offsiteUsername = config.offsiteUsername
                configurations?[index].executepretask = config.executepretask
                configurations?[index].pretask = config.pretask
                configurations?[index].executeposttask = config.executepretask
                configurations?[index].posttask = config.posttask
                configurations?[index].haltshelltasksonerror = config.haltshelltasksonerror
                configurations?[index].backupID = config.backupID
            }
            WriteConfigurationJSON(localeprofile, configurations)
                .saveconfigInMemoryToPersistentStore()
        }
    }

    // Function deletes Configuration in memory at hiddenID and
    // then saves updated Configurations from memory to persistent store.
    // Function computes index by hiddenID.
    private func removeconfiguration(hiddenID: Int) {
        if let index = configurations?.firstIndex(where: { $0.hiddenID == hiddenID }) {
            configurations?.remove(at: index)
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
                .saveconfigInMemoryToPersistentStore()
        }
    }

    // Add new configurations
    func addconfiguration(_ config: Configuration) -> Bool {
        let beforecount = (configurations?.count ?? 0)
        var newconfig: Configuration = config
        newconfig.hiddenID = maxhiddenID + 1
        configurations?.append(newconfig)
        let aftercount = (configurations?.count ?? 0)
        WriteConfigurationJSON(localeprofile, configurations)
            .saveconfigInMemoryToPersistentStore()
        if aftercount > beforecount {
            return true
        } else {
            return false
        }
    }

    private func increasesnapshotnum(index: Int) {
        if let num = configurations?[index].snapshotnum {
            configurations?[index].snapshotnum = num + 1
        }
    }

    init(profile: String?, configurations: [Configuration]?) {
        localeprofile = profile
        // Create new set of configurations
        if configurations == nil {
            self.configurations = [Configuration]()
        } else {
            self.configurations = configurations
        }
    }

    deinit {
        // print("deinit UpdateConfigurations")
    }
}
