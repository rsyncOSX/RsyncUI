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
    func createprofilecatalog(profile: String) -> Bool {
        var rootpath: Folder?
        if let path = fullroot {
            do {
                rootpath = try Folder(path: path)
                do {
                    try rootpath?.createSubfolder(at: profile)
                    return true
                } catch let e {
                    let error = e
                    self.propogateerror(error: error)
                    return false
                }
            } catch {
                return false
            }
        }
        return false
    }

    init() {
        super.init(profileorsshrootpath: .profileroot)
    }
}
