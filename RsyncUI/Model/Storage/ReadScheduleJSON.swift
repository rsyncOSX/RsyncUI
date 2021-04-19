//
//  ReadScheduleJSON.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 19/04/2021.
//

//
//  ReadWriteJSON.swift
//  RsyncOSX
//
//  Created by Thomas Evensen on 29/10/2020.
//  Copyright © 2020 Thomas Evensen. All rights reserved.
//

import Combine
import Files
import Foundation

class ReadScheduleJSON: NamesandPaths {
    var schedulesjson: [ConfigurationSchedule]?
    var datafiles = ["schedules.json"]
    var subscriptons = Set<AnyCancellable>()

    var jsonstring: String?

    func writeJSONToPersistentStore() {
        if var atpath = fullroot {
            do {
                if profile != nil {
                    atpath += "/" + (profile ?? "")
                }
                let folder = try Folder(path: atpath)
                let file = try folder.createFile(named: filename ?? "")
                if let data = jsonstring {
                    try file.write(data)
                }
            } catch let e {
                let error = e
                self.propogateerror(error: error)
            }
        }
    }

    func writeconvertedtostore() {
        if var atpath = fullroot {
            if profile != nil {
                atpath += "/" + (profile ?? "")
            }
            writeJSONToPersistentStore()
        }
    }

    func readJSONFromPersistentStore() throws -> String? {
        if var atpath = fullroot {
            do {
                if profile != nil {
                    atpath += "/" + (profile ?? "")
                }
                // check if file exists befor reading, if not bail out
                guard try Folder(path: atpath).containsFile(named: filename ?? "") else { return nil }
                let jsonfile = atpath + "/" + (filename ?? "")
                let file = try File(path: jsonfile)
                return try file.readAsString()
            } catch let e {
                let error = e
                self.propogateerror(error: error)
                return nil
            }
        }
        return nil
    }

    override init(profile: String?, whattoreadwrite: WhatToReadWrite) {
        super.init(profileorsshrootpath: .profileroot)
        if whattoreadwrite == .configuration {
            filename = SharedReference.shared.fileconfigurationsjson
        } else {
            filename = SharedReference.shared.fileschedulesjson
        }
        self.profile = profile

        datafiles.publisher
            .compactMap { filename -> URL? in
                let name = fullroot! + "/" + filename
                return URL(fileURLWithPath: name)
            }
            .tryMap { url -> Data in
                try Data(contentsOf: url)
            }
            .decode(type: [DecodeSchedule].self, decoder: JSONDecoder())
            .sink { completion in
                print("completion with \(completion)")
            } receiveValue: { [unowned self] data in
                print(data)
            }.store(in: &subscriptons)
    }
}

