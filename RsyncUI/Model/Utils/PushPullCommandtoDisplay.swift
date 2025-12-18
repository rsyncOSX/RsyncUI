//
//  PushPullCommandtoDisplay.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 07/12/2024.
//
// swiftlint:disable line_length

import Foundation
import SSHCreateKey

enum PushPullCommand: String, CaseIterable, Identifiable, CustomStringConvertible {
    case pullRemote
    case pushLocal
    case none

    var id: String { rawValue }
    var description: String { rawValue.localizedCapitalized.replacingOccurrences(of: "_", with: " ") }
}

@MainActor
struct PushPullCommandtoDisplay {
    var command: String

    init(display: PushPullCommand,
         config: SynchronizeConfiguration,
         dryRun: Bool,
         keepdelete: Bool) {
        var str = ""
        switch display {
        case .pullRemote:
            if config.offsiteServer.isEmpty == false, config.task == SharedReference.shared.synchronize {
                if let arguments = ArgumentsPullRemote(config: config).argumentspullremotewithparameters(dryRun: dryRun,
                                                                                                         forDisplay: true, keepdelete: keepdelete) {
                    str = (GetfullpathforRsync().rsyncpath()) + " " + arguments.joined()
                }
            } else {
                str = "Use macOS Finder"
            }
        case .pushLocal:
            if config.offsiteServer.isEmpty == false, config.task == SharedReference.shared.synchronize {
                if let arguments = ArgumentsSynchronize(config: config).argumentsforpushlocaltoremotewithparameters(dryRun: dryRun,
                                                                                                                    forDisplay: true, keepdelete: keepdelete) {
                    str = (GetfullpathforRsync().rsyncpath()) + " " + arguments.joined()
                }
            } else {
                str = "Use macOS Finder"
            }
        case .none:
            str = "Select either pull or push"
        }
        command = str
    }
}

// swiftlint:enable line_length
