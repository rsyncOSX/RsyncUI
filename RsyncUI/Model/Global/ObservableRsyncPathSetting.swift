//
//  ObservableUsersetting.swift
//  RsyncSwiftUI
//
//  Created by Thomas Evensen on 16/02/2021.
//

import Foundation
import Observation

@Observable @MainActor
final class ObservableRsyncPathSetting: PropogateError {
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
    // Detailed logging
    var addsummarylogrecord: Bool = SharedReference.shared.addsummarylogrecord
    var logtofile: Bool = SharedReference.shared.logtofile
    // Mark number of days since last backup
    var marknumberofdayssince = String(SharedReference.shared.marknumberofdayssince)
    // Check for network changes
    var monitornetworkconnection: Bool = SharedReference.shared.monitornetworkconnection
    // True if on ARM based Mac
    var macosarm: Bool = SharedReference.shared.macosarm
    // Check for "error" in output from rsync
    var checkforerrorinrsyncoutput: Bool = SharedReference.shared.checkforerrorinrsyncoutput
    // Automatic execution of estimated tasks
    var confirmexecute: Bool = SharedReference.shared.confirmexecute

    // Only validate path if rsyncver3 is true
    func setandvalidatepathforrsync(_ path: String) {
        guard path.isEmpty == false, rsyncversion3 == true else {
            // Set rsync path = nil
            let validate = SetandValidatepathforrsync()
            validate.setlocalrsyncpath("")
            return
        }
        let validate = SetandValidatepathforrsync()
        validate.setlocalrsyncpath(path)
        do {
            _ = try validate.validateandrsyncpath()
        } catch let e {
            SharedReference.shared.rsyncversionshort = "No valid rsync detected"
            let error = e
            propogateerror(error: error)
            return
        }
    }

    func setandvalidapathforrestore(_ atpath: String) {
        guard atpath.isEmpty == false else {
            // Delete path
            SharedReference.shared.pathforrestore = nil
            return
        }
        do {
            let ok = try validatepath(atpath)
            if ok {
                SharedReference.shared.pathforrestore = atpath
            }
        } catch let e {
            let error = e
            propogateerror(error: error)
            return
        }
    }

    private func validatepath(_ path: String) throws -> Bool {
        let fm = FileManager.default
        if fm.fileExists(atPath: path, isDirectory: nil) == false {
            throw Validatedpath.nopath
        }
        return true
    }

    // Automatic execute time
    private func verifystringtoint(_ seconds: String) throws -> Bool {
        guard seconds.isEmpty == false else { return false }
        if Int(seconds) != nil {
            return true
        } else {
            throw InputError.notvalidInt
        }
    }

    func markdays(days: String) {
        do {
            let verified = try verifystringtoint(days)
            if verified {
                SharedReference.shared.marknumberofdayssince = Int(days) ?? 5
            }
        } catch let e {
            let error = e
            propogateerror(error: error)
            return
        }
    }
}

enum Validatedpath: LocalizedError {
    case nopath
    // case noerror

    var errorDescription: String? {
        switch self {
        case .nopath:
            "No such path"
        }
    }
}

enum InputError: LocalizedError {
    case notvalidInt

    var errorDescription: String? {
        switch self {
        case .notvalidInt:
            "Not a valid number (Int)"
        }
    }
}
