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
    func updateconfiguration(_ config: Configuration) {
        if let index = configurations?.firstIndex(where: { $0.hiddenID == config.hiddenID }) {
            configurations?[index] = config
            PersistentStorage(profile: localeprofile,
                              whattoreadorwrite: .configuration,
                              readonly: false,
                              configurations: configurations,
                              schedules: nil)
                .saveMemoryToPersistentStore()
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
        if let configurations = configurations {
            let selectedconfigs = configurations.filter { uuids.contains($0.id) }
            guard selectedconfigs.count > 0 else { return }
            for i in 0 ..< selectedconfigs.count {
                removeconfiguration(hiddenID: selectedconfigs[i].hiddenID)
            }
        }
        // No need for deleting the logs, only valid hiddenIDs are
        // loaded next time configurations are read from
        // permanent store
        PersistentStorage(profile: localeprofile,
                          whattoreadorwrite: .configuration,
                          readonly: false,
                          configurations: configurations,
                          schedules: nil)
            .saveMemoryToPersistentStore()
    }

    // Add new configurations
    func addconfiguration(_ config: Configuration) -> Bool {
        let beforecount = (configurations?.count ?? 0)
        var newconfig: Configuration = config
        newconfig.hiddenID = maxhiddenID + 1
        configurations?.append(newconfig)
        let aftercount = (configurations?.count ?? 0)
        PersistentStorage(profile: localeprofile,
                          whattoreadorwrite: .configuration,
                          readonly: false,
                          configurations: configurations,
                          schedules: nil)
            .saveMemoryToPersistentStore()
        if aftercount > beforecount {
            return true
        } else {
            return false
        }
    }

    func removecompressparameter(index: Int, delete: Bool) {
        guard index < (configurations?.count ?? 0) else { return }
        if delete {
            configurations?[index].parameter3 = ""
        } else {
            configurations?[index].parameter3 = "--compress"
        }
    }

    func removeedeleteparameter(index: Int, delete: Bool) {
        guard index < (configurations?.count ?? 0) else { return }
        if delete {
            configurations?[index].parameter4 = ""
        } else {
            configurations?[index].parameter4 = "--delete"
        }
    }

    func removeesshparameter(index: Int, delete: Bool) {
        guard index < (configurations?.count ?? 0) else { return }
        if delete {
            configurations?[index].parameter5 = ""
        } else {
            configurations?[index].parameter5 = "-e"
        }
    }

    private func increasesnapshotnum(index: Int) {
        if let num = configurations?[index].snapshotnum {
            configurations?[index].snapshotnum = num + 1
        }
    }

    init(profile: String?,
         configurations: [Configuration]?)
    {
        localeprofile = profile
        self.configurations = configurations
    }

    deinit {
        print("deinit UpdateConfigurations")
    }
}
