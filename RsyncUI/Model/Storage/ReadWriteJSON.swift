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
                    
                    if SharedReference.shared.menuappisrunning {
                        Notifications().showNotification(SharedReference.shared.reloadstring)
                        DistributedNotificationCenter.default().postNotificationName(NSNotification.Name(SharedReference.shared.reloadstring), object: nil, deliverImmediately: true)
                    }
                    
                }
            } catch let e {
                let error = e
                self.propogateerror(error: error)
            }
        }
    }

    override init(_ profile: String?) {
        super.init(profileorsshrootpath: .profileroot)
        self.profile = profile
    }
}
