//
//  Readwritefiles.swift
//  RsyncOSX
//
//  Created by Thomas Evensen on 25/10/2016.
//  Copyright © 2016 Thomas Evensen. All rights reserved.
//
// swiftlint:disable line_length

import Cocoa
import Foundation

class ReadWriteDictionary: NamesandPaths {
    // Function for write data to persistent store
    @discardableResult
    func writeNSDictionaryToPersistentStorage(array: [NSDictionary]) -> Bool {
        let dictionary = NSDictionary(object: array, forKey: SharedReference.shared.userconfigkey as NSCopying)
        let write = dictionary.write(toFile: filename ?? "", atomically: true)
        if write && SharedReference.shared.menuappisrunning {
            Notifications().showNotification("Sending reload message to menu app")
            DistributedNotificationCenter.default().postNotificationName(NSNotification.Name(SharedReference.shared.reloadstring), object: nil, deliverImmediately: true)
        }
        return write
    }

    override init(_ profile: String?) {
        super.init(profile)
    }
}
