//
//  CatalogProfile.swift
//  RsyncOSX
//
//  Created by Thomas Evensen on 17/10/2016.
//  Copyright © 2016 Thomas Evensen. All rights reserved.
//

import Foundation

final class CatalogProfile {
    let path = Homepath()

    func createprofilecatalog(profile: String) {
        var rootpath: Folder?
        if let path = path.fullpathmacserial {
            do {
                rootpath = try Folder(path: path)
                // check if profile exist
                do {
                    let profilepath = path + "/" + profile
                    _ = try Folder(path: profilepath)

                } catch {
                    do {
                        try rootpath?.createSubfolder(at: profile)
                    } catch let e {
                        let error = e
                        self.path.propogateerror(error: error)
                    }
                }
            } catch {}
        }
    }

    // Function for deleting profile directory
    func deleteprofilecatalog(profileName: String) {
        let fileManager = FileManager.default
        if let path = path.fullpathmacserial {
            let profileDirectory = path + "/" + profileName
            if fileManager.fileExists(atPath: profileDirectory) == true {
                do {
                    try fileManager.removeItem(atPath: profileDirectory)
                } catch let e {
                    let error = e as NSError
                    self.path.propogateerror(error: error)
                }
            }
        }
    }

    init() {}
}
