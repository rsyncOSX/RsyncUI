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
                Logger.process.info("GetfullpathforRsync OPTIONAL path: \(localrsyncpath, privacy: .public)")

                if localrsyncpath.hasPrefix("/") {
                    return localrsyncpath + SharedReference.shared.rsync
                } else {
                    return localrsyncpath.appending("/") + SharedReference.shared.rsync
                }
            } else {
                if SharedReference.shared.macosarm {
                    Logger.process.info("GetfullpathforRsync HOMEBREW path ARM: \(SharedReference.shared.usrlocalbinarm.appending("/"), privacy: .public)")
                } else {
                    Logger.process.info("GetfullpathforRsync HOMEBREW path INTEL: \(SharedReference.shared.usrlocalbin.appending("/"), privacy: .public)")
                }
                if SharedReference.shared.macosarm {
                    return SharedReference.shared.usrlocalbinarm.appending("/") + SharedReference.shared.rsync
                } else {
                    return SharedReference.shared.usrlocalbin.appending("/") + SharedReference.shared.rsync
                }
            }
        } else {
            Logger.process.info("GetfullpathforRsync DEFAULT path: \(SharedReference.shared.usrbin.appending("/"), privacy: .public)")
            return SharedReference.shared.usrbin.appending("/") + SharedReference.shared.rsync
        }
    }
}
