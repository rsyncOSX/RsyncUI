//
//  Rsyncpath.swift
//  RsyncOSX
//
//  Created by Thomas Evensen on 06/06/2019.
//  Copyright © 2019 Thomas Evensen. All rights reserved.
//

import Foundation

enum Validatedrsync: LocalizedError {
    case norysnc

    var errorDescription: String? {
        switch self {
        case .norysnc:
            return NSLocalizedString("There is no rsync in path", comment: "no rsync") + "..."
        }
    }
}

struct SetandValidatepathforrsync {
    func validateandrsyncpath() throws -> Bool {
        var rsyncpath: String?
        // If not in /usr/bin or /usr/local/bin, rsyncPath is set if none of the above
        if let pathforrsync = SharedReference.shared.localrsyncpath {
            rsyncpath = pathforrsync + SharedReference.shared.rsync
        } else if SharedReference.shared.rsyncversion3 {
            rsyncpath = SharedReference.shared.usrlocalbin + "/" + SharedReference.shared.rsync
        } else {
            rsyncpath = SharedReference.shared.usrbin + "/" + SharedReference.shared.rsync
        }
        // Bail out and return true if stock rsync is used
        guard SharedReference.shared.rsyncversion3 == true else {
            SharedReference.shared.norsync = false
            return true
        }
        if FileManager.default.isExecutableFile(atPath: rsyncpath ?? "") == false {
            SharedReference.shared.norsync = true
            // Throwing no valid rsync in path
            throw Validatedrsync.norysnc
        } else {
            SharedReference.shared.norsync = false
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

    func getpathforrsync() -> String {
        if SharedReference.shared.rsyncversion3 == true {
            return SharedReference.shared.localrsyncpath ?? SharedReference.shared.usrlocalbin
        } else {
            return SharedReference.shared.usrbin
        }
    }
}
