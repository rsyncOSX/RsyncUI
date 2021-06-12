//
//  profiles.swift
//  RsyncOSX
//
//  Created by Thomas Evensen on 17/10/2016.
//  Copyright © 2016 Thomas Evensen. All rights reserved.
//

import Files
import Foundation

final class CatalogProfile: Catalogsandfiles {
    func createprofilecatalog(profile: String) {
        var rootpath: Folder?
        if let path = fullpathmacserial {
            do {
                rootpath = try Folder(path: path)
                // check if profile exist
                do {
                    let profilepath = path + "/" + profile
                    try Folder(path: profilepath)
                } catch {
                    do {
                        try rootpath?.createSubfolder(at: profile)
                    } catch let e {
                        let error = e
                        propogateerror(error: error)
                    }
                }
            } catch {}
        }
    }

    // Function for deleting profile directory
    func deleteprofilecatalog(profileName: String) {
        let fileManager = FileManager.default
        if let path = fullpathmacserial {
            let profileDirectory = path + "/" + profileName
            if fileManager.fileExists(atPath: profileDirectory) == true {
                do {
                    try fileManager.removeItem(atPath: profileDirectory)
                } catch let e {
                    let error = e as NSError
                    propogateerror(error: error)
                }
            }
        }
    }

    init() {
        super.init(.configurations)
    }
}
