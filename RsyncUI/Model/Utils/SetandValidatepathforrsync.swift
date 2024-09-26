//
//  SetandValidatepathforrsync.swift
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
            "No rsync in path"
        case .noversion3inusrbin:
            "No ver3 of rsync in /usr/bin"
        }
    }
}

@MainActor
struct SetandValidatepathforrsync {
    func validateandrsyncpath() throws  {
        let fm = FileManager.default
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
                if fm.isExecutableFile(atPath: rsyncpath ?? "") == false {
                    SharedReference.shared.norsync = true
                    // Throwing no valid rsync in path
                    throw Validatedrsync.norsync
                }
                return
            case false:
                return
            }
        } else {
            // Use default values for either ver3 or ver3
            return
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

    func getpathforrsync() -> String {
        if SharedReference.shared.rsyncversion3 == true {
            if SharedReference.shared.macosarm {
                if SharedReference.shared.localrsyncpath == nil {
                    return SharedReference.shared.usrlocalbinarm
                }
            } else if SharedReference.shared.localrsyncpath == nil {
                return SharedReference.shared.usrlocalbin
            }
        }
        SharedReference.shared.rsyncversion3 = false
        return SharedReference.shared.usrbin
    }
}
