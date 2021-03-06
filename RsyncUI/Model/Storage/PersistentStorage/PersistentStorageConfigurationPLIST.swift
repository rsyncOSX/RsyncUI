//
//  PersistentStoreageConfiguration.swift
//  RsyncOSX
//
//  Created by Thomas Evensen on 09/12/15.
//  Copyright © 2015 Thomas Evensen. All rights reserved.
//
// swiftlint:disable line_length opening_brace

import Files
import Foundation

class PersistentStorageConfigurationPLIST: ReadWriteDictionary {
    // Variable holds all configuration data from persisten storage
    var configurationsasdictionary: [NSDictionary]?
    var configurations: [Configuration]?

    // Saving Configuration from MEMORY to persistent store
    // Reads Configurations from MEMORY and saves to persistent Store
    func saveconfigInMemoryToPersistentStore() {
        var array = [NSDictionary]()
        if let configurations = self.configurations {
            for i in 0 ..< configurations.count {
                if let dict: NSMutableDictionary = ConvertConfigurations(index: i, configurations: self.configurations).configurationNSMutableDictionry {
                    array.append(dict)
                }
            }
            writeToStore(array: array)
        }
    }

    func writeconfigstostoreasplist() {
        let root = NamesandPaths(profileorsshrootpath: .profileroot)
        if var atpath = root.fullroot {
            if profile != nil {
                atpath += "/" + (profile ?? "")
            }
            saveconfigInMemoryToPersistentStore()
        }
    }

    // Writing configuration to persistent store
    // Configuration is [NSDictionary]
    private func writeToStore(array: [NSDictionary]) {
        if writeNSDictionaryToPersistentStorage(array: array) {}
    }

    init(profile: String?) {
        super.init(profile: profile, whattoreadwrite: .configuration)
        if configurations == nil {
            configurationsasdictionary = readNSDictionaryFromPersistentStore()
        }
    }

    init(profile: String?,
         readonly: Bool,
         configurations: [Configuration]?)
    {
        super.init(profile: profile, whattoreadwrite: .configuration)
        self.configurations = configurations
        if readonly {
            configurationsasdictionary = readNSDictionaryFromPersistentStore()
        } else {
            writeconfigstostoreasplist()
        }
    }
}
