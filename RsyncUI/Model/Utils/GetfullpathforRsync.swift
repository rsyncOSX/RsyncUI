//
//  GetfullpathforRsync.swift
//  RsyncOSX
//
//  Created by Thomas Evensen on 06/06/2019.
//  Copyright © 2019 Thomas Evensen. All rights reserved.
//

import Foundation

struct GetfullpathforRsync {
    var rsyncpath: String?

    init() {
        if SharedReference.shared.rsyncversion3 {
            if let localrsyncpath = SharedReference.shared.localrsyncpath {
                // localrsyncpath is set with trailing "/"
                rsyncpath = localrsyncpath + SharedReference.shared.rsync
            } else {
                if SharedReference.shared.macosarm {
                    rsyncpath = SharedReference.shared.usrlocalbinarm + "/" + SharedReference.shared.rsync
                } else {
                    rsyncpath = SharedReference.shared.usrlocalbin + "/" + SharedReference.shared.rsync
                }
            }
        } else {
            rsyncpath = SharedReference.shared.usrbin + "/" + SharedReference.shared.rsync
        }
    }
}
