//
//  Verifyrsyncpath.swift
//  RsyncOSX
//
//  Created by Thomas Evensen on 22.07.2017.
//  Copyright © 2017 Thomas Evensen. All rights reserved.
//
// swiftlint:disable cyclomatic_complexity opening_brace

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

    init(index: Int,
         display: RsyncCommand,
         allarguments: [ArgumentsOneConfiguration]?)
    {
        guard index > -1 else { return }
        var str = ""
        if allarguments?.count ?? 0 > 0 {
            guard index < (allarguments?.count ?? 0) else { return }
            str = GetfullpathforRsync().rsyncpath ?? ""
            str += " "
            switch display {
            case .synchronize:
                if let count = allarguments?[index].argdryRunDisplay?.count {
                    for i in 0 ..< count {
                        str += (allarguments?[index].argdryRunDisplay?[i] ?? "")
                    }
                }
            case .restore:
                if let count = allarguments?[index].restoredryRunDisplay?.count {
                    for i in 0 ..< count {
                        str += (allarguments?[index].restoredryRunDisplay?[i] ?? "")
                    }
                }
            case .verify:
                if let count = allarguments?[index].verifyDisplay?.count {
                    for i in 0 ..< count {
                        str += (allarguments?[index].verifyDisplay?[i] ?? "")
                    }
                }
            }
            rsynccommand = str
        }
    }
}
