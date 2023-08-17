//
//  ObservableUsersetting.swift
//  RsyncSwiftUI
//
//  Created by Thomas Evensen on 16/02/2021.
//

import Foundation
import Observation

@Observable
final class ObservableUsersetting {
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
    var detailedlogging: Bool = SharedReference.shared.detailedlogging
    // Logging to logfile
    var minimumlogging: Bool = SharedReference.shared.minimumlogging
    var fulllogging: Bool = SharedReference.shared.fulllogging
    var nologging: Bool = SharedReference.shared.nologging
    // Mark number of days since last backup
    var marknumberofdayssince = String(SharedReference.shared.marknumberofdayssince)
    // Paths for apps
    // @Published var pathrsyncui: String = SharedReference.shared.pathrsyncui ?? ""
    // @Published var pathrsyncschedule: String = SharedReference.shared.pathrsyncschedule ?? ""
    // Check for network changes
    var monitornetworkconnection: Bool = SharedReference.shared.monitornetworkconnection
    // True if on ARM based Mac
    var macosarm: Bool = SharedReference.shared.macosarm
    // Check for "error" in output from rsync
    var checkforerrorinrsyncoutput: Bool = SharedReference.shared.checkforerrorinrsyncoutput
    // alert about error
    var error: Error = Validatedpath.noerror
    var alerterror: Bool = false

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
            error = e
            alerterror = true
        }
    }

    // Set default version 2 of rsync values
    private func setdefaultvaulesrsync() {
        let validate = SetandValidatepathforrsync()
        validate.setdefaultvaluesver2rsync()
        rsyncversion3 = false
        localrsyncpath = ""
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
            error = e
            alerterror = true
        }
    }

    private func validatepath(_ path: String) throws -> Bool {
        if FileManager.default.fileExists(atPath: path, isDirectory: nil) == false {
            throw Validatedpath.nopath
        }
        return true
    }

    // Mark days
    private func checkmarkdays(_ days: String) throws -> Bool {
        guard days.isEmpty == false else { return false }
        if Double(days) != nil {
            return true
        } else {
            throw InputError.notvalidDouble
        }
    }

    func markdays(days: String) {
        do {
            let verified = try checkmarkdays(days)
            if verified {
                SharedReference.shared.marknumberofdayssince = Double(days) ?? 5
            }
        } catch let e {
            error = e
            alerterror = true
        }
    }
}

enum Validatedpath: LocalizedError {
    case nopath
    case noerror

    var errorDescription: String? {
        switch self {
        case .nopath:
            return "No such path"
        case .noerror:
            return ""
        }
    }
}
