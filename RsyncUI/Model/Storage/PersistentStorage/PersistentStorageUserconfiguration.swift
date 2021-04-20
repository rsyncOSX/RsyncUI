//
//  PersistentStoreageUserconfiguration.swift
//  RsyncOSX
//
//  Created by Thomas Evensen on 26/10/2016.
//  Copyright © 2016 Thomas Evensen. All rights reserved.
//

import Foundation

final class PersistentStorageUserconfiguration: ReadWriteDictionary {
    // Save user configuration
    func saveuserconfiguration() {
        if let array: [NSDictionary] = ConvertUserconfiguration().userconfiguration {
            writeToStore(array: array)
        }
    }

    // Read userconfiguration
    func readuserconfiguration() -> [NSDictionary]? {
        return readNSDictionaryFromPersistentStore()
    }

    // Writing configuration to persistent store
    // Configuration is [NSDictionary]
    private func writeToStore(array: [NSDictionary]) {
        // Getting the object just for the write method, no read from persistent store
        _ = writeNSDictionaryToPersistentStorage(array: array)
    }

    init() {
        super.init(profile: nil)
    }

    deinit {
        // print("deinit PersistentStorageUserconfiguration")
    }
}
