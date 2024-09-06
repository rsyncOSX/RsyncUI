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

    var deleted: Bool = false
    var created: Bool = false

    var confirmdeleteselectedprofile: Bool = false
    var showAlertfordelete: Bool = false

    var selectedconfig: SynchronizeConfiguration?

    func createprofile(newprofile: String) {
        guard newprofile.isEmpty == false else { return }
        let catalogprofile = CatalogForProfile()
        catalogprofile.createprofilecatalog(newprofile)
        selectedprofile = newprofile
        created = true
    }

    func deleteprofile(_ profile: String?) {
        guard confirmdeleteselectedprofile == true else { return }
        if let profile {
            guard profile != SharedReference.shared.defaultprofile else {
                deletedefaultprofile = true
                Task {
                    try await Task.sleep(seconds: 1)
                    deletedefaultprofile = false
                }
                return
            }
            CatalogForProfile().deleteprofilecatalog(profile)
            selectedprofile = nil
            deleted = true
        } else {
            deletedefaultprofile = true
            Task {
                try await Task.sleep(seconds: 1)
                deletedefaultprofile = false
            }
        }
    }
}
// swiftlint:enable line_length

