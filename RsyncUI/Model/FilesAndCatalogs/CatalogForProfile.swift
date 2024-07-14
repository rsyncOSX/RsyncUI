//
//  CatalogForProfile.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 17/10/2016.
//  Copyright © 2016 Thomas Evensen. All rights reserved.
//

import Foundation
import OSLog

@MainActor
struct CatalogForProfile: PropogateError {
    let path = Homepath()

    func createprofilecatalog(_ profile: String) {
        let fm = FileManager.default
        // First check if profilecatalog exists, if yes bail out
        if let fullpathmacserial = path.fullpathmacserial {
            let fullpathprofileString = fullpathmacserial + "/" + profile
            guard fm.locationExists(at: fullpathprofileString, kind: .folder) == false else {
                Logger.process.info("CatalogProfile: profile catalog exist")
                return
            }

            let fullpathmacserialURL = URL(fileURLWithPath: fullpathmacserial)
            let profileURL = fullpathmacserialURL.appendingPathComponent(profile)

            do {
                try fm.createDirectory(at: profileURL, withIntermediateDirectories: true, attributes: nil)
                Logger.process.info("CatalogProfile: creating profile catalog")
            } catch let e {
                let error = e
                propogateerror(error: error)
                return
            }
        }
    }

    // Function for deleting profile directory
    func deleteprofilecatalog(_ profile: String) {
        let fm = FileManager.default
        if let fullpathmacserial = path.fullpathmacserial {
            let fullpathprofileString = fullpathmacserial + "/" + profile
            let fullpathmacserialURL = URL(fileURLWithPath: fullpathmacserial)
            let profileURL = fullpathmacserialURL.appendingPathComponent(profile)

            guard fm.locationExists(at: fullpathprofileString, kind: .folder) == true else {
                Logger.process.info("CatalogProfile: profile catalog does not exist")
                return
            }
            do {
                try fm.removeItem(at: profileURL)
                Logger.process.info("CatalogProfile: remove profile catalog")
            } catch let e {
                let error = e as NSError
                self.path.propogateerror(error: error)
            }
        }
    }
}
