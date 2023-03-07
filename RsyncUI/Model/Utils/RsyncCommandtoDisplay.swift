//
//  Verifyrsyncpath.swift
//  RsyncOSX
//
//  Created by Thomas Evensen on 22.07.2017.
//  Copyright © 2017 Thomas Evensen. All rights reserved.
//
// swiftlint:disable line_length opening_brace

import Foundation

protocol Setinfoaboutrsync: AnyObject {
    func setinfoaboutrsync()
}

enum RsyncCommand: String, CaseIterable, Identifiable, CustomStringConvertible {
    case synchronize
    case restore
    case verify

    var id: String { rawValue }
    var description: String { rawValue.localizedCapitalized }
}

struct RsyncCommandtoDisplay {
    private var rsynccommand: String?

    func getrsyncommand() -> String? {
        return rsynccommand
    }

    init(display: RsyncCommand,
         config: Configuration)
    {
        var str = ""
        str = GetfullpathforRsync().rsyncpath ?? ""
        str += " "
        switch display {
        case .synchronize:
            if let arguments = ArgumentsSynchronize(config: config).argumentssynchronize(dryRun: true, forDisplay: true) {
                for i in 0 ..< arguments.count {
                    str += arguments[i]
                }
            }
        case .restore:
            if let arguments = ArgumentsRestore(config: config, restoresnapshotbyfiles: false).argumentsrestore(dryRun: true, forDisplay: true, tmprestore: false) {
                for i in 0 ..< arguments.count {
                    str += arguments[i]
                }
            }
        case .verify:
            if let arguments = ArgumentsVerify(config: config).argumentsverify(forDisplay: true) {
                for i in 0 ..< arguments.count {
                    str += arguments[i]
                }
            }
        }
        rsynccommand = str
    }
}
