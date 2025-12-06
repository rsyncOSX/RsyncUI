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
                Logger.process.debugMessageOnly("CatalogProfile: profile catalog exist: \(fullpathprofileString)")
                return false
            }

            let fullpathmacserialURL = URL(fileURLWithPath: fullpathmacserial)
            let profileURL = fullpathmacserialURL.appendingPathComponent(profile)

            do {
                Logger.process.debugMessageOnly("CatalogProfile creating: \(profileURL)")
                try fm.createDirectory(at: profileURL, withIntermediateDirectories: true, attributes: nil)
            } catch let e {
                let error = e
                path.propagateError(error: error)
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
                return false
            }
            do {
                try fm.removeItem(at: profileURL)
            } catch let e {
                let error = e as NSError
                path.propagateError(error: error)
                return false
            }
        }
        return true
    }
}
