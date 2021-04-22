//
//  WriteConfigurationJSON.swift
//  RsyncOSX
//
//  Created by Thomas Evensen on 20/10/2020.
//  Copyright © 2020 Thomas Evensen. All rights reserved.
//
// swiftlint:disable line_length opening_brace

import Foundation

class WriteConfigurationJSON: ReadWriteJSON {
    var configurations: [Configuration]?

    // Saving Configuration from MEMORY to persistent store
    // Reads Configurations from MEMORY and saves to persistent Store
    func saveconfigInMemoryToPersistentStore() {
        createJSONfromstructs()
        writeJSONToPersistentStore()
        if SharedReference.shared.menuappisrunning {
            Notifications().showNotification("Sending reload message to menu app")
            DistributedNotificationCenter.default().postNotificationName(NSNotification.Name(SharedReference.shared.reloadstring), object: nil, deliverImmediately: true)
        }
    }

    private func createJSONfromstructs() {
        var structscodable: [Configuration]?
        if let configurations = self.configurations {
            structscodable = [Configuration]()
            for i in 0 ..< configurations.count {
                structscodable?.append(Configuration(config: configurations[i]))
            }
        }
        jsonstring = encodedata(data: structscodable)
    }

    private func encodedata(data: [Configuration]?) -> String? {
        do {
            let jsonData = try JSONEncoder().encode(data)
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                return jsonString
            }
        } catch let e {
            let error = e
            self.propogateerror(error: error)
        }
        return nil
    }

    init(_ profile: String?, _ configurations: [Configuration]?) {
        super.init(profile)
        filename = SharedReference.shared.fileconfigurationsjson
        self.profile = profile
        self.configurations = configurations
    }
}
