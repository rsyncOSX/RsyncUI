//
//  RsyncCommandtoDisplay.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 22.07.2017.
//

import Foundation

enum RsyncCommand: String, CaseIterable, Identifiable, CustomStringConvertible {
    case synchronizeData = "synchronize_data"
    case restoreData = "restore_data"
    case verifySynchronizedData = "verify_synchronized_data"

    var id: String { rawValue }
    var description: String { rawValue.localizedCapitalized.replacingOccurrences(of: "_", with: " ") }
}

@MainActor
struct RsyncCommandtoDisplay {
    var rsynccommand: String

    init(display: RsyncCommand,
         config: SynchronizeConfiguration) {
        var str = ""
        switch display {
        case .synchronizeData:
            if config.task == SharedReference.shared.halted {
                str = "Task is halted"
            } else {
                if let arguments = ArgumentsSynchronize(config: config).argumentsSynchronize(dryRun: true, forDisplay: true) {
                    str = (GetfullpathforRsync().rsyncpath()) + " " + arguments.joined()
                }
            }
        case .restoreData:
            if let arguments = ArgumentsRestore(config: config, restoresnapshotbyfiles: false).argumentsrestore(dryRun: true,
                                                                                                                forDisplay: true) {
                str = (GetfullpathforRsync().rsyncpath()) + " " + arguments.joined()
            }
        case .verifySynchronizedData:
            if config.task == SharedReference.shared.halted {
                str = "Task is halted"
            } else {
                if let arguments = ArgumentsVerify(config: config).argumentsverify(forDisplay: true) {
                    str = (GetfullpathforRsync().rsyncpath()) + " " + arguments.joined()
                }
            }
        }
        rsynccommand = str
    }
}
