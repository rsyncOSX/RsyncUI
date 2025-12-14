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

    func createProfileCatalog(_ profile: String?) -> Bool {
        let fmanager = FileManager.default
        // First check if profilecatalog exists, if yes bail out
        if let fullpathmacserial = path.fullpathmacserial, let profile {
            let fullpathprofileString = fullpathmacserial.appending("/") + profile
            guard fmanager.locationExists(at: fullpathprofileString, kind: .folder) == false else {
                Logger.process.debugMessageOnly("CatalogProfile: profile catalog exist: \(fullpathprofileString)")
                return false
            }

            let fullpathmacserialURL = URL(fileURLWithPath: fullpathmacserial)
            let profileURL = fullpathmacserialURL.appendingPathComponent(profile)

            do {
                Logger.process.debugMessageOnly("CatalogProfile creating: \(profileURL)")
                try fmanager.createDirectory(at: profileURL, withIntermediateDirectories: true, attributes: nil)
            } catch let err {
                let error = err
                path.propagateError(error: error)
                return false
            }
        }
        return true
    }

    // Function for deleting profile directory
    func deleteProfileCatalog(_ profile: String?) -> Bool {
        let fmanager = FileManager.default
        if let fullpathmacserial = path.fullpathmacserial, let profile {
            let fullpathprofileString = fullpathmacserial.appending("/") + profile
            let fullpathmacserialURL = URL(fileURLWithPath: fullpathmacserial)
            let profileURL = fullpathmacserialURL.appendingPathComponent(profile)

            guard fmanager.locationExists(at: fullpathprofileString, kind: .folder) == true else {
                return false
            }
            do {
                try fmanager.removeItem(at: profileURL)
            } catch let err {
                let error = err as NSError
                path.propagateError(error: error)
                return false
            }
        }
        return true
    }
}
