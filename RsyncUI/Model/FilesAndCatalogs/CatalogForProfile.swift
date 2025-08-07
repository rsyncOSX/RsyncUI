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
struct CatalogForProfile {
    let path = Homepath()

    func createprofilecatalog(_ profile: String?) -> Bool {
        let fm = FileManager.default
        // First check if profilecatalog exists, if yes bail out
        if let fullpathmacserial = path.fullpathmacserial, let profile {
            let fullpathprofileString = fullpathmacserial.appending("/") + profile
            guard fm.locationExists(at: fullpathprofileString, kind: .folder) == false else {
                Logger.process.info("CatalogProfile: profile catalog exist: \(fullpathprofileString, privacy: .public)")
                return false
            }

            let fullpathmacserialURL = URL(fileURLWithPath: fullpathmacserial)
            let profileURL = fullpathmacserialURL.appendingPathComponent(profile)

            do {
                Logger.process.info("CatalogProfile creating: \(profileURL, privacy: .public)")
                try fm.createDirectory(at: profileURL, withIntermediateDirectories: true, attributes: nil)
            } catch let e {
                let error = e
                path.propogateerror(error: error)
                return false
            }
        }
        return true
    }

    // Function for deleting profile directory
    func deleteprofilecatalog(_ profile: String?) -> Bool {
        let fm = FileManager.default
        if let fullpathmacserial = path.fullpathmacserial, let profile {
            let fullpathprofileString = fullpathmacserial.appending("/") + profile
            let fullpathmacserialURL = URL(fileURLWithPath: fullpathmacserial)
            let profileURL = fullpathmacserialURL.appendingPathComponent(profile)

            guard fm.locationExists(at: fullpathprofileString, kind: .folder) == true else {
                Logger.process.info("CatalogProfile: profile catalog does not exist \(fullpathprofileString, privacy: .public)")
                return false
            }
            do {
                Logger.process.info("CatalogProfile: deleted \(profileURL) catalog")
                try fm.removeItem(at: profileURL)
            } catch let e {
                let error = e as NSError
                path.propogateerror(error: error)
                return false
            }
        }
        return true
    }
}
