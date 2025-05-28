//
//  GetfullpathforRsync.swift
//  RsyncOSX
//
//  Created by Thomas Evensen on 06/06/2019.
//  Copyright © 2019 Thomas Evensen. All rights reserved.
//

import Foundation
import OSLog

@MainActor
struct GetfullpathforRsync {
    func rsyncpath() -> String? {
        guard SharedReference.shared.norsync == false else { return nil }
        if SharedReference.shared.rsyncversion3 {
            if let localrsyncpath = SharedReference.shared.localrsyncpath,
               localrsyncpath.isEmpty == false
            {
                if localrsyncpath.hasPrefix("/") {
                    Logger.process.info("GetfullpathforRsync localrsyncpath: \(localrsyncpath, privacy: .public)")
                    return localrsyncpath + SharedReference.shared.rsync
                } else {
                    Logger.process.info("GetfullpathforRsync localrsyncpath: \(localrsyncpath.appending("/"), privacy: .public)")
                    return localrsyncpath.appending("/") + SharedReference.shared.rsync
                }
            } else {
                if SharedReference.shared.macosarm {
                    Logger.process.info("GetfullpathforRsync macosArm usrlocalbinarm: \(SharedReference.shared.usrlocalbinarm.appending("/"), privacy: .public)")
                    return SharedReference.shared.usrlocalbinarm.appending("/") + SharedReference.shared.rsync
                } else {
                    Logger.process.info("GetfullpathforRsync usrlocalbin: \(SharedReference.shared.usrlocalbin.appending("/"), privacy: .public)")
                    return SharedReference.shared.usrlocalbin.appending("/") + SharedReference.shared.rsync
                }
            }
        } else {
            Logger.process.info("GetfullpathforRsync usrbin: \(SharedReference.shared.usrbin.appending("/"), privacy: .public)")
            return SharedReference.shared.usrbin.appending("/") + SharedReference.shared.rsync
        }
    }
}
