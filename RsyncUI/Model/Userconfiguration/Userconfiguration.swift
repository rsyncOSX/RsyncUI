//
//  userconfiguration.swift
//  RsyncOSXver30
//
//  Created by Thomas Evensen on 24/08/2016.
//  Copyright © 2016 Thomas Evensen. All rights reserved.
//
// swiftlint:disable line_length cyclomatic_complexity function_body_length

import Foundation

// Reading userconfiguration from file into RsyncOSX
struct Userconfiguration {
    private func readUserconfiguration(dict: NSDictionary) {
        SharedReference.shared.inloading = true
        // Another version of rsync
        if let version3rsync = dict.value(forKey: DictionaryStrings.version3Rsync.rawValue) as? Int {
            if version3rsync == 1 {
                SharedReference.shared.rsyncversion3 = true
            } else {
                SharedReference.shared.rsyncversion3 = false
            }
        }
        // Detailed logging
        if let detailedlogging = dict.value(forKey: DictionaryStrings.detailedlogging.rawValue) as? Int {
            if detailedlogging == 1 {
                SharedReference.shared.detailedlogging = true
            } else {
                SharedReference.shared.detailedlogging = false
            }
        }
        // Optional path for rsync
        if let rsyncPath = dict.value(forKey: DictionaryStrings.rsyncPath.rawValue) as? String {
            SharedReference.shared.localrsyncpath = rsyncPath
            validatepathforrsync(rsyncPath)
        }
        // Temporary path for restores single files or directory
        if let restorePath = dict.value(forKey: DictionaryStrings.restorePath.rawValue) as? String {
            if restorePath.count > 0 {
                SharedReference.shared.pathforrestore = restorePath
            } else {
                SharedReference.shared.pathforrestore = nil
            }
        }
        // Mark tasks
        if let marknumberofdayssince = dict.value(forKey: DictionaryStrings.marknumberofdayssince.rawValue) as? String {
            if Double(marknumberofdayssince) ?? 0 > 0 {
                SharedReference.shared.marknumberofdayssince = Double(marknumberofdayssince)!
            }
        }
        // Paths rsyncOSX and RsyncOSXsched
        if let pathrsyncosx = dict.value(forKey: DictionaryStrings.pathrsyncosx.rawValue) as? String {
            if pathrsyncosx.isEmpty == true {
                SharedReference.shared.pathrsyncosx = nil
            } else {
                SharedReference.shared.pathrsyncosx = pathrsyncosx
            }
        }
        if let pathrsyncosxsched = dict.value(forKey: DictionaryStrings.pathrsyncosxsched.rawValue) as? String {
            if pathrsyncosxsched.isEmpty == true {
                SharedReference.shared.pathrsyncosxsched = nil
            } else {
                SharedReference.shared.pathrsyncosxsched = pathrsyncosxsched
            }
        }
        // No logging, minimum logging or full logging
        if let minimumlogging = dict.value(forKey: DictionaryStrings.minimumlogging.rawValue) as? Int {
            if minimumlogging == 1 {
                SharedReference.shared.minimumlogging = true
            } else {
                SharedReference.shared.minimumlogging = false
            }
        }
        if let fulllogging = dict.value(forKey: DictionaryStrings.fulllogging.rawValue) as? Int {
            if fulllogging == 1 {
                SharedReference.shared.fulllogging = true
            } else {
                SharedReference.shared.fulllogging = false
            }
        }
        if let environment = dict.value(forKey: DictionaryStrings.environment.rawValue) as? String {
            SharedReference.shared.environment = environment
        }
        if let environmentvalue = dict.value(forKey: DictionaryStrings.environmentvalue.rawValue) as? String {
            SharedReference.shared.environmentvalue = environmentvalue
        }
        if let sshkeypathandidentityfile = dict.value(forKey: DictionaryStrings.sshkeypathandidentityfile.rawValue) as? String {
            SharedReference.shared.sshkeypathandidentityfile = sshkeypathandidentityfile
        }
        if let sshport = dict.value(forKey: DictionaryStrings.sshport.rawValue) as? Int {
            SharedReference.shared.sshport = sshport
        }
        if let monitornetworkconnection = dict.value(forKey: DictionaryStrings.monitornetworkconnection.rawValue) as? Int {
            if monitornetworkconnection == 1 {
                SharedReference.shared.monitornetworkconnection = true
            } else {
                SharedReference.shared.monitornetworkconnection = false
            }
        }
        if let json = dict.value(forKey: DictionaryStrings.json.rawValue) as? Int {
            if json == 1 {
                SharedReference.shared.json = true
            } else {
                SharedReference.shared.json = false
            }
        }
        SharedReference.shared.inloading = false
    }

    func validatepathforrsync(_ path: String) {
        let validate = SetandValidatepathforrsync()
        validate.setlocalrsyncpath(path)
        do {
            let ok = try validate.validateandrsyncpath()
            if ok { return }
        } catch let e {
            let error = e
            self.propogateerror(error: error)
        }
    }

    func propogateerror(error: Error) {
        SharedReference.shared.errorobject?.propogateerror(error: error)
    }

    init(userconfigRsyncOSX: [NSDictionary]) {
        if userconfigRsyncOSX.count > 0 {
            readUserconfiguration(dict: userconfigRsyncOSX[0])
        }
    }
}
