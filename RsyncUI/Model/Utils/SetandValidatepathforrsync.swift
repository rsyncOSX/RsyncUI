//
//  Rsyncpath.swift
//  RsyncOSX
//
//  Created by Thomas Evensen on 06/06/2019.
//  Copyright © 2019 Thomas Evensen. All rights reserved.
//

import Foundation

enum Validatedrsync: LocalizedError {
    case norsync
    case noversion3inusrbin

    var errorDescription: String? {
        switch self {
        case .norsync:
            return "No rsync in path"
        case .noversion3inusrbin:
            return "No ver3 of rsync in /usr/bin"
        }
    }
}

struct SetandValidatepathforrsync {
    func validateandrsyncpath() throws -> Bool {
        // Set default that rsync path is validated
        SharedReference.shared.norsync = false
        var rsyncpath: String?
        // First check if a local path is set or use default values
        // Only validate path if rsyncversion is true, set default values else
        if let pathforrsync = SharedReference.shared.localrsyncpath {
            switch SharedReference.shared.rsyncversion3 {
            case true:
                rsyncpath = pathforrsync + SharedReference.shared.rsync
                // Check that version rsync 3 is not set to /usr/bin - throw if true
                guard SharedReference.shared.localrsyncpath != (SharedReference.shared.usrbin + "/") else {
                    throw Validatedrsync.noversion3inusrbin
                }
                if FileManager.default.isExecutableFile(atPath: rsyncpath ?? "") == false {
                    SharedReference.shared.norsync = true
                    // Throwing no valid rsync in path
                    throw Validatedrsync.norsync
                }
                return true
            case false:
                return true
            }
        } else {
            // Use default values for either ver3 or ver3
            return true
        }
    }

    func setlocalrsyncpath(_ path: String) {
        var path = path
        if path.isEmpty == false {
            if path.hasSuffix("/") == false {
                path += "/"
                SharedReference.shared.localrsyncpath = path
            } else {
                SharedReference.shared.localrsyncpath = path
            }
        } else {
            SharedReference.shared.localrsyncpath = nil
        }
    }

    func setdefaultvaluesver2rsync() {
        SharedReference.shared.localrsyncpath = nil
        SharedReference.shared.rsyncversion3 = false
    }

    func getpathforrsync() -> String {
        if SharedReference.shared.rsyncversion3 == true {
            return SharedReference.shared.localrsyncpath ?? SharedReference.shared.usrlocalbin
        } else {
            return SharedReference.shared.usrbin
        }
    }
}
