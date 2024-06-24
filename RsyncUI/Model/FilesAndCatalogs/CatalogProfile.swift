//
//  CatalogProfile.swift
//  RsyncOSX
//
//  Created by Thomas Evensen on 17/10/2016.
//  Copyright © 2016 Thomas Evensen. All rights reserved.
//

import Foundation
import OSLog

@MainActor
struct CatalogProfile {
    let path = Homepath()

    func createprofilecatalog(profile: String) {
        let fm = FileManager.default
        // First check if profilecatalog exists, if yes bail out
        if let fullpathmacserial = path.fullpathmacserial {
            guard fm.locationExists(at: fullpathmacserial + "/" + profile, kind: .folder) == false else {
                Logger.process.info("CatalogProfile: profile catalog exists")
                return
            }
            let fullpathprofileURL = URL(fileURLWithPath: fullpathmacserial + "/" + profile)
            do {
                try fm.createDirectory(at: fullpathprofileURL, withIntermediateDirectories: true)
                Logger.process.info("CatalogProfile: creating profile catalog")
            } catch let e {
                let error = e
                propogateerror(error: error)
                return
            }
        }
    }

    // Function for deleting profile directory
    func deleteprofilecatalog(profileName: String) {
        let fm = FileManager.default
        if let path = path.fullpathmacserial {
            let profileDirectory = path + "/" + profileName
            if fm.fileExists(atPath: profileDirectory) == true {
                do {
                    try fm.removeItem(atPath: profileDirectory)
                } catch let e {
                    let error = e as NSError
                    self.path.propogateerror(error: error)
                }
            }
        }
    }
}

extension CatalogProfile {
    @MainActor func propogateerror(error: Error) {
        SharedReference.shared.errorobject?.alert(error: error)
    }
}
