//
//  GetfullpathforRsync.swift
//  RsyncOSX
//
//  Created by Thomas Evensen on 06/06/2019.
//  Copyright © 2019 Thomas Evensen. All rights reserved.
//

import Foundation

@MainActor
struct GetfullpathforRsync {
    func rsyncpath() -> String? {
        guard SharedReference.shared.norsync == false else { return nil }
        if SharedReference.shared.rsyncversion3 {
            if let localrsyncpath = SharedReference.shared.localrsyncpath,
               localrsyncpath.isEmpty == false
            {
                if localrsyncpath.hasPrefix("/") {
                    return localrsyncpath + SharedReference.shared.rsync
                } else {
                    return localrsyncpath + "/" + SharedReference.shared.rsync
                }
            } else {
                if SharedReference.shared.macosarm {
                    return SharedReference.shared.usrlocalbinarm + "/" + SharedReference.shared.rsync
                } else {
                    return SharedReference.shared.usrlocalbin + "/" + SharedReference.shared.rsync
                }
            }
        } else {
            return SharedReference.shared.usrbin + "/" + SharedReference.shared.rsync
        }
    }
}
