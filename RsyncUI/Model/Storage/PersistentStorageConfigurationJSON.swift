//
//  PersistentStorageConfigurationJSON.swift
//  RsyncOSX
//
//  Created by Thomas Evensen on 20/10/2020.
//  Copyright © 2020 Thomas Evensen. All rights reserved.
//
// swiftlint:disable line_length opening_brace

import Foundation

class PersistentStorageConfigurationJSON: ReadWriteJSON {
    var decodedjson: [Any]?
    var configurations: [Configuration]?

    // Saving Configuration from MEMORY to persistent store
    // Reads Configurations from MEMORY and saves to persistent Store
    func saveconfigInMemoryToPersistentStore() {
        if let configurations = self.configurations {
            writeToStore(configurations: configurations)
        }
    }

    private func writeToStore(configurations _: [Configuration]?) {
        createJSONfromstructs()
        writeJSONToPersistentStore()
        if SharedReference.shared.menuappisrunning {
            Notifications().showNotification("Sending reload message to menu app")
            DistributedNotificationCenter.default().postNotificationName(NSNotification.Name("no.blogspot.RsyncUI.reload"), object: nil, deliverImmediately: true)
        }
    }

    private func createJSONfromstructs() {
        var structscodable: [CodableConfiguration]?
        if let configurations = self.configurations {
            structscodable = [CodableConfiguration]()
            for i in 0 ..< configurations.count {
                structscodable?.append(CodableConfiguration(config: configurations[i]))
            }
        }
        jsonstring = encodedata(data: structscodable)
    }

    private func encodedata(data: [CodableConfiguration]?) -> String? {
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

    private func decode(jsonfileasstring: String) {
        if let jsonstring = jsonfileasstring.data(using: .utf8) {
            do {
                let decoder = JSONDecoder()
                decodedjson = try decoder.decode([DecodeConfiguration].self, from: jsonstring)
            } catch let e {
                let error = e
                self.propogateerror(error: error)
            }
        }
    }

    func JSONFromPersistentStore() {
        do {
            if let jsonfile = try readJSONFromPersistentStore() {
                guard jsonfile.isEmpty == false else { return }
                decode(jsonfileasstring: jsonfile)
            }
        } catch let e {
            let error = e
            self.propogateerror(error: error)
        }
    }

    init(profile: String?) {
        super.init(profile: profile, whattoreadwrite: .configuration)
        self.profile = profile
        if configurations == nil {
            JSONFromPersistentStore()
        }
    }

    init(profile: String?,
         configurations: [Configuration]?)
    {
        super.init(profile: profile, whattoreadwrite: .configuration)
        self.profile = profile
        self.configurations = configurations
        createJSONfromstructs()
        writeconvertedtostore()
    }
}
