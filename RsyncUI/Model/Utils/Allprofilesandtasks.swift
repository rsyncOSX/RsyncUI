//
//  Allprofilesandtasks.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 21/03/2023.
//

@MainActor
final class Allprofilesandtasks {
    var allprofiles: [String]? {
        Homepath().getfullpathmacserialcatalogsasstringnames()
    }

    private func readalltasks() {
        for i in 0 ..< (allprofiles?.count ?? 0) {
            let profilename = allprofiles?[i]
            if profilename == "Default profile" {
                let configurations = ReadSynchronizeConfigurationJSON(nil).configurations
            } else {
                let configurations = ReadSynchronizeConfigurationJSON(profilename).configurations
            }
        }
    }
    
    func markconfig(_ seconds: Double) -> Bool {
        seconds / (60 * 60 * 24) > Double(SharedReference.shared.marknumberofdayssince)
    }

    init() {
        readalltasks()
    }
}
