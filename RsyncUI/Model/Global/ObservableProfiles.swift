//
//  ObservableProfiles.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 06/09/2024.
//

import Foundation
import Observation

@Observable @MainActor
final class ObservableProfiles {
    func createProfile(_ newprofile: String) -> Bool {
        guard newprofile != "Default" else { return false }
        guard newprofile != "default" else { return false }
        guard newprofile.isEmpty == false else { return false }
        let catalogprofile = CatalogForProfile()
        if catalogprofile.createProfileCatalog(newprofile) {
            return true
        } else {
            return false
        }
    }

    func deleteProfile(_ profile: String?) -> Bool {
        guard profile != nil else { return false }
        if CatalogForProfile().deleteProfileCatalog(profile) {
            return true
        } else {
            return false
        }
    }
}
