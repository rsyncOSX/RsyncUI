//
//  ReadWriteJSON.swift
//  RsyncOSX
//
//  Created by Thomas Evensen on 29/10/2020.
//  Copyright © 2020 Thomas Evensen. All rights reserved.
//

import Files
import Foundation

class ReadWriteJSON: NamesandPaths {
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

    override init(profile: String?, whattoreadwrite: WhatToReadWrite) {
        super.init(profileorsshrootpath: .profileroot)
        if whattoreadwrite == .configuration {
            filename = SharedReference.shared.fileconfigurationsjson
        } else {
            filename = SharedReference.shared.fileschedulesjson
        }
        self.profile = profile
    }
}
