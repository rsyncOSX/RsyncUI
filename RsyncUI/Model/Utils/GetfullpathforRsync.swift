//
//  GetfullpathforRsync.swift
//  RsyncUI
//
/* swiftlint:disable line_length */

import Foundation
import OSLog

@MainActor
struct GetfullpathforRsync {
    func rsyncpath() -> String {
        guard SharedReference.shared.norsync == false else { return "no rsync in path" }
        if SharedReference.shared.rsyncversion3 {
            if let localrsyncpath = SharedReference.shared.localrsyncpath,
               localrsyncpath.isEmpty == false {
                Logger.process.debugMessageOnly("GetfullpathforRsync OPTIONAL path: \(localrsyncpath)")

                if localrsyncpath.hasPrefix("/") {
                    return localrsyncpath + SharedReference.shared.rsync
                } else {
                    return localrsyncpath.appending("/") + SharedReference.shared.rsync
                }
            } else {
                if SharedReference.shared.macosarm {
                    Logger.process.debugMessageOnly(
                        "GetfullpathforRsync HOMEBREW path ARM: \(SharedReference.shared.usrlocalbinarm.appending("/"))"
                    )
                } else {
                    Logger.process.debugMessageOnly(
                        "GetfullpathforRsync HOMEBREW path INTEL: \(SharedReference.shared.usrlocalbin.appending("/"))"
                    )
                }
                if SharedReference.shared.macosarm {
                    return SharedReference.shared.usrlocalbinarm.appending("/") + SharedReference.shared.rsync
                } else {
                    return SharedReference.shared.usrlocalbin.appending("/") + SharedReference.shared.rsync
                }
            }
        } else {
            Logger.process.debugMessageOnly("GetfullpathforRsync DEFAULT path: \(SharedReference.shared.usrbin.appending("/"))")
            return SharedReference.shared.usrbin.appending("/") + SharedReference.shared.rsync
        }
    }
}

/* swiftlint:enable line_length */
