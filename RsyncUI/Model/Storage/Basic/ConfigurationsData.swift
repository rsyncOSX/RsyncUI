//
//  ConfigurationsData.swift
//  RsyncOSX
//
//  Created by Thomas Evensen on 15/11/2020.
//  Copyright © 2020 Thomas Evensen. All rights reserved.
//

import Foundation

final class ConfigurationsData {
    // The main structure storing all Configurations for tasks
    var configurations: [Configuration]?
    var localprofile: String?
    // valid hiddenIDs
    var validhiddenIDs: Set<Int>?
    var persistentstorage: PersistentStorage?
    // uniqueue servers and logins
    var uniqueserversandlogins: [UniqueserversandLogins]?

    // Getting all unique remote servers and logins
    // Used in SSH settings
    func setuniqueserversandlogins() {
        let configs = configurations?.filter {
            SharedReference.shared.synctasks.contains($0.task)
        }
        guard configs?.count ?? 0 > 0 else { return }
        uniqueserversandlogins = [UniqueserversandLogins]()
        for i in 0 ..< (configs?.count ?? 0) {
            if let config = configs?[i] {
                if config.offsiteUsername.isEmpty == false, config.offsiteServer.isEmpty == false {
                    let record = UniqueserversandLogins(config.offsiteUsername, config.offsiteServer)
                    if uniqueserversandlogins?.filter({ ($0.offsiteUsername == record.offsiteUsername) &&
                            ($0.offsiteServer == record.offsiteServer)
                    }).count == 0 {
                        uniqueserversandlogins?.append(record)
                    }
                }
            }
        }
    }

    func readconfigurationsplist() {
        if let store = persistentstorage?.configPLIST?.configurationsasdictionary {
            for i in 0 ..< store.count {
                let dict = store[i]
                var config = Configuration(dictionary: dict)
                config.profile = localprofile
                if SharedReference.shared.synctasks.contains(config.task) {
                    if validhiddenIDs?.contains(config.hiddenID) == false {
                        configurations?.append(config)
                        validhiddenIDs?.insert(config.hiddenID)
                    }
                }
            }
        }
    }

    func readconfigurationsjson() {
        if let store = persistentstorage?.configJSON?.decodedjson {
            let transform = TransformConfigfromJSON()
            for i in 0 ..< store.count {
                if let configitem = store[i] as? DecodeConfiguration {
                    let transformed = transform.transform(object: configitem)
                    if SharedReference.shared.synctasks.contains(transformed.task) {
                        if validhiddenIDs?.contains(transformed.hiddenID) == false {
                            configurations?.append(transformed)
                            validhiddenIDs?.insert(transformed.hiddenID)
                        }
                    }
                }
            }
        }
    }

    init(profile: String?) {
        localprofile = profile
        configurations = nil
        configurations = [Configuration]()
        validhiddenIDs = Set()
        persistentstorage = PersistentStorage(profile: localprofile,
                                              whattoreadorwrite: .configuration)
        readconfigurationsjson()
        readconfigurationsplist()
        setuniqueserversandlogins()
    }
}
