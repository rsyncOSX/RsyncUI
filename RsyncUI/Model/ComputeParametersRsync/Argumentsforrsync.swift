//
//  Argumentsforrsync.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 02/07/2023.
//

import Foundation

@MainActor
struct Argumentsforrsync {
    // Function return arguments for rsync, either arguments for
    // real runn or arguments for --dry-run for Configuration at selected index
    func argumentsforrsync(config: SynchronizeConfiguration, argtype: ArgumentsRsync) -> [String] {
        switch argtype {
        case .arg:
            ArgumentsSynchronize(config: config).argumentssynchronize(dryRun: false,
                                                                      forDisplay: false) ?? []
        case .argdryRun:
            ArgumentsSynchronize(config: config).argumentssynchronize(dryRun: true,
                                                                      forDisplay: false) ?? []
        }
    }
}

// Used to select argument
enum ArgumentsRsync {
    case arg
    case argdryRun
}
