//
//  PersistentStoreageUserconfiguration.swift
//  RsyncOSX
//
//  Created by Thomas Evensen on 26/10/2016.
//  Copyright © 2016 Thomas Evensen. All rights reserved.
//

import Foundation

final class PersistentStorageUserconfiguration: NamesandPaths {
    // Save user configuration
    func saveuserconfiguration() {
        if let array: [NSDictionary] = ConvertUserconfiguration().userconfiguration {
            writeNSDictionaryToPersistentStorage(array: array)
        }
    }

    @discardableResult
    func writeNSDictionaryToPersistentStorage(array: [NSDictionary]) -> Bool {
        let dictionary = NSDictionary(object: array, forKey: SharedReference.shared.userconfigkey as NSCopying)
        let write = dictionary.write(toFile: filename ?? "", atomically: true)
        if write && SharedReference.shared.menuappisrunning {
            Notifications().showNotification("Sending reload message to menu app")
            DistributedNotificationCenter.default()
                .postNotificationName(NSNotification.Name(SharedReference.shared.reloadstring),
                                      object: nil, deliverImmediately: true)
        }
        return write
    }

    init() {
        super.init(nil)
    }

    deinit {
        // print("deinit PersistentStorageUserconfiguration")
    }
}
