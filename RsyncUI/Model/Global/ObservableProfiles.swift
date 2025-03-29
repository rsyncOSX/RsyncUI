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
    func createprofile(_ newprofile: String) -> Bool {
        guard newprofile.isEmpty == false else { return false }
        let catalogprofile = CatalogForProfile()
        if catalogprofile.createprofilecatalog(newprofile) {
            return true
        } else {
            return false
        }
    }

    func deleteprofile(_ profile: String) -> Bool {
        guard profile != SharedConstants().defaultprofile else { return false }
        if CatalogForProfile().deleteprofilecatalog(profile) {
            return true
        } else {
            return false
        }
    }
}
