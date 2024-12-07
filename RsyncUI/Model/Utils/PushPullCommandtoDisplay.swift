//
//  PushPullCommandtoDisplay.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 07/12/2024.
//

import Foundation
import SSHCreateKey

enum PushPullCommand: String, CaseIterable, Identifiable, CustomStringConvertible {
    case pull_remote
    case push_local
    
    var id: String { rawValue }
    var description: String { rawValue.localizedCapitalized.replacingOccurrences(of: "_", with: " ") }
}

@MainActor
struct PushPullCommandtoDisplay {
    var command: String

    init(display: PushPullCommand,
         config: SynchronizeConfiguration)
    {
        var str = ""
        switch display {
        
        case .pull_remote:
            if config.offsiteServer.isEmpty == false {
                if let arguments = ArgumentsPullRemote(config: config).argumentspullremotewithparameters(dryRun: true, forDisplay: true) {
                    str = (GetfullpathforRsync().rsyncpath() ?? "no rsync in path ") + " " + arguments.joined()
                }
            } else {
                str = NSLocalizedString("Use macOS Finder", comment: "")
            }
        case .push_local:
            if config.offsiteServer.isEmpty == false {
                if let arguments = ArgumentsSynchronize(config: config).argumentsforpushlocaltoremote(dryRun: true, forDisplay: true) {
                    str = (GetfullpathforRsync().rsyncpath() ?? "no rsync in path ") + " " + arguments.joined()
                }
            } else {
                str = NSLocalizedString("Use macOS Finder", comment: "")
            }
        }
        command = str
    }
}

// swiftlint:enable line_length opening_brace

