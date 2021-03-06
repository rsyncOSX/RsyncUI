//
//  profiles.swift
//  RsyncOSX
//
//  Created by Thomas Evensen on 17/10/2016.
//  Copyright © 2016 Thomas Evensen. All rights reserved.
//

import Files
import Foundation

final class CatalogProfile: Catalogsandfiles {
    func createprofilecatalog(profile: String) -> Bool {
        var rootpath: Folder?
        if let path = fullroot {
            do {
                rootpath = try Folder(path: path)
                do {
                    try rootpath?.createSubfolder(at: profile)
                    return true
                } catch let e {
                    let error = e
                    self.propogateerror(error: error)
                    return false
                }
            } catch {
                return false
            }
        }
        return false
    }

    // Function for deleting profile directory
    func deleteProfileDirectory(profileName: String) {
        let fileManager = FileManager.default
        if let path = fullroot {
            let profileDirectory = path + "/" + profileName
            if fileManager.fileExists(atPath: profileDirectory) == true {
                let question: String = NSLocalizedString("Delete profile:", comment: "Profiles")
                let text: String = NSLocalizedString("Cancel or Delete", comment: "Profiles")
                let dialog: String = NSLocalizedString("Delete", comment: "Profiles")
                let answer = Alerts.dialogOrCancel(question: question + " " + profileName
                    + "?", text: text, dialog: dialog)
                if answer {
                    do {
                        try fileManager.removeItem(atPath: profileDirectory)
                    } catch let e {
                        let error = e
                        self.propogateerror(error: error)
                    }
                }
            }
        }
    }

    init() {
        super.init(profileorsshrootpath: .profileroot)
    }
}
