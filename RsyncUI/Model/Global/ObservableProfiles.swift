//
//  ObservableProfiles.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 06/09/2024.
//

import Foundation
import Observation

@Observable @MainActor
final class ObservableProfiles: PropogateError {
    var selectedprofile: String?
    var deletedefaultprofile: Bool = false

    // var deleted: Bool = false
    // var created: Bool = false

    func createprofile(_ newprofile: String) -> Bool {
        guard newprofile.isEmpty == false else { return false }
        let catalogprofile = CatalogForProfile()
        if catalogprofile.createprofilecatalog(newprofile) {
            selectedprofile = newprofile
            return true
        } else {
            return false
        }
    }

    func deleteprofile(_ profile: String) -> Bool {
            guard profile != SharedReference.shared.defaultprofile else { return false }
            if CatalogForProfile().deleteprofilecatalog(profile) {
                selectedprofile = nil
                return true
            } else {
                return false
            }
        }
}
