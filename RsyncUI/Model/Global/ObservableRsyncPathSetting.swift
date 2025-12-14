//
//  ObservableRsyncPathSetting.swift
//  RsyncSwiftUI
//
//  Created by Thomas Evensen on 16/02/2021.
//

import Foundation
import Observation
import OSLog

@Observable @MainActor
final class ObservableRsyncPathSetting {
    // True if version 3.1.2 or 3.1.3 of rsync in /usr/local/bin
    var rsyncversion3: Bool = SharedReference.shared.rsyncversion3
    // Optional path to rsync, the settings View is picking up the current value
    // Set the current value as placeholder text
    var localrsyncpath: String = ""
    // No valid rsyncPath - true if no valid rsync is found
    var norsync: Bool = false
    // Temporary path for restore, the settings View is picking up the current value
    // Set the current value as placeholder text
    var temporarypathforrestore: String = ""
    // Mark number of days since last backup
    var marknumberofdayssince = String(SharedReference.shared.marknumberofdayssince)
    // True if on ARM based Mac
    var macosarm: Bool = SharedReference.shared.macosarm

    // Used for mark local path red or white
    func verifypathforrsync(_ path: String) -> Bool {
        let fmanager = FileManager.default
        switch SharedReference.shared.rsyncversion3 {
        case true:
            let rsyncpath = path.appending("/") + SharedReference.shared.rsync
            if fmanager.isExecutableFile(atPath: rsyncpath) == false {
                return false
            } else {
                return true
            }
        case false:
            return false
        }
    }

    func verifyPathForRestore(_ path: String) -> Bool {
        let fmanager = FileManager.default
        return fmanager.fileExists(atPath: path, isDirectory: nil)
    }

    // Only validate path if rsyncver3 is true
    func setandvalidatepathforrsync(_ path: String) -> Bool {
        guard path.isEmpty == false, rsyncversion3 == true else {
            // Set rsync path = nil
            let validate = SetandValidatepathforrsync()
            validate.setlocalrsyncpath("")
            return false
        }
        let validate = SetandValidatepathforrsync()
        validate.setlocalrsyncpath(path)
        do {
            try validate.validateLocalPathForRsync()
            return true
        } catch {
            SharedReference.shared.rsyncversionshort = "No valid rsync detected"
            return false
        }
    }

    func verifystringtoint(_ days: String) -> Bool {
        if Int(days) != nil {
            true
        } else {
            false
        }
    }

    func markdays(days: String) {
        let verified = verifystringtoint(days)
        if verified {
            SharedReference.shared.marknumberofdayssince = Int(days) ?? 5
        } else {
            SharedReference.shared.marknumberofdayssince = 5
        }
    }
}
