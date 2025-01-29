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
    case synchronize_data
    case restore_data
    case verify_synchronized_data

    var id: String { rawValue }
    var description: String { rawValue.localizedCapitalized.replacingOccurrences(of: "_", with: " ") }
}

@MainActor
struct RsyncCommandtoDisplay {
    var rsynccommand: String

    init(display: RsyncCommand,
         config: SynchronizeConfiguration)
    {
        var str = ""
        switch display {
        case .synchronize_data:
            if config.task == SharedReference.shared.halted {
                str = "Task is halted"
            } else {
                if let arguments = ArgumentsSynchronize(config: config).argumentssynchronize(dryRun: true, forDisplay: true) {
                    str = (GetfullpathforRsync().rsyncpath() ?? "no rsync in path ") + " " + arguments.joined()
                }
            }
        case .restore_data:
            if let arguments = ArgumentsRestore(config: config, restoresnapshotbyfiles: false).argumentsrestore(dryRun: true, forDisplay: true) {
                str = (GetfullpathforRsync().rsyncpath() ?? "no rsync in path ") + " " + arguments.joined()
            }
        case .verify_synchronized_data:
            if config.task == SharedReference.shared.halted {
                str = "Task is halted"
            } else {
                if let arguments = ArgumentsVerify(config: config).argumentsverify(forDisplay: true) {
                    str = (GetfullpathforRsync().rsyncpath() ?? "no rsync in path ") + " " + arguments.joined()
                }
            }
        }
        rsynccommand = str
    }
}

// swiftlint:enable line_length opening_brace
