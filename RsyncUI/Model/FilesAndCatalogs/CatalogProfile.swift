//
//  CatalogProfile.swift
//  RsyncOSX
//
//  Created by Thomas Evensen on 17/10/2016.
//  Copyright © 2016 Thomas Evensen. All rights reserved.
//

import Foundation

enum ProfileexistsError: LocalizedError {
    case profileexists

    var errorDescription: String? {
        switch self {
        case .profileexists:
            return "Profile exists"
        }
    }
}

final class CatalogProfile: Catalogsandfiles {
    func createprofilecatalog(profile: String) {
        var rootpath: Folder?
        if let path = fullpathmacserial {
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
                        alerterror(error: error)
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
                    alerterror(error: error)
                }
            }
        }
    }

    init() {
        super.init(.configurations)
    }
}
