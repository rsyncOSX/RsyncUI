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
    case pull_remote
    case push_local
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
        case .pull_remote:
            if config.offsiteServer.isEmpty == false, config.task == SharedReference.shared.synchronize {
                if let arguments = ArgumentsPullRemote(config: config).argumentspullremotewithparameters(dryRun: dryRun,
                                                                                                         forDisplay: true, keepdelete: keepdelete) {
                    str = (GetfullpathforRsync().rsyncpath()) + " " + arguments.joined()
                }
            } else {
                str = "Use macOS Finder"
            }
        case .push_local:
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
