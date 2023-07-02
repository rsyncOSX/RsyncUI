//
//  Argumentsforrsync.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 02/07/2023.
//

import Foundation

struct Argumentsforrsync {
    // Function return arguments for rsync, either arguments for
    // real runn or arguments for --dry-run for Configuration at selected index
    func argumentsforrsync(config: Configuration, argtype: ArgumentsRsync) -> [String] {
        switch argtype {
        case .arg:
            return ArgumentsSynchronize(config: config).argumentssynchronize(dryRun: false,
                                                                             forDisplay: false) ?? []
        case .argdryRun:
            return ArgumentsSynchronize(config: config).argumentssynchronize(dryRun: true,
                                                                             forDisplay: false) ?? []
        case .argdryRunlocalcataloginfo:
            guard config.task != SharedReference.shared.syncremote else { return [] }
            return ArgumentsLocalcatalogInfo(config: config).argumentslocalcataloginfo(dryRun: true,
                                                                                       forDisplay: false) ?? []
        }
    }
}
