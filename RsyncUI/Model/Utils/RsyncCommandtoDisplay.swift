//
//  RsyncCommandtoDisplay.swift
//  RsyncOSX
//
//  Created by Thomas Evensen on 22.07.2017.
//  Copyright © 2017 Thomas Evensen. All rights reserved.
//
// swiftlint:disable line_length opening_brace

import Foundation

enum RsyncCommand: String, CaseIterable, Identifiable, CustomStringConvertible {
    case synchronize
    case restore
    case verify

    var id: String { rawValue }
    var description: String { rawValue.localizedCapitalized }
}

@MainActor
struct RsyncCommandtoDisplay {
    var rsynccommand: String?

    init(display: RsyncCommand,
         config: SynchronizeConfiguration)
    {
        var str = ""
        switch display {
        case .synchronize:
            if let arguments = ArgumentsSynchronize(config: config).argumentssynchronize(dryRun: true, forDisplay: true) {
                str = (GetfullpathforRsync().rsyncpath() ?? "no rsync in path ") + " " + arguments.joined()
            }
        case .restore:
            if let arguments = ArgumentsRestore(config: config, restoresnapshotbyfiles: false).argumentsrestore(dryRun: true, forDisplay: true) {
                str = (GetfullpathforRsync().rsyncpath() ?? "no rsync in path ") + " " + arguments.joined()
            }
        case .verify:
            if let arguments = ArgumentsVerify(config: config).argumentsverify(forDisplay: true) {
                str = (GetfullpathforRsync().rsyncpath() ?? "no rsync in path ") + " " + arguments.joined()
            }
        }
        rsynccommand = str
    }
}

// swiftlint:enable line_length opening_brace
