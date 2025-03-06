//
//  OtherRsyncCommandtoDisplay.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 16/09/2024.
//

// swiftlint:disable line_length opening_brace

import Foundation
import SSHCreateKey

enum OtherRsyncCommand: String, CaseIterable, Identifiable, CustomStringConvertible {
    case list_remote_files
    case create_public_SSHkey
    case copy_public_SSHkey
    case verify_public_SSHkey
    case remote_disk_usage
    case push_data_to_remote_server
    case pull_data_from_remote_server

    var id: String { rawValue }
    var description: String { rawValue.localizedCapitalized.replacingOccurrences(of: "_", with: " ") }
}

@MainActor
struct OtherRsyncCommandtoDisplay {
    var command: String

    init(display: OtherRsyncCommand,
         config: SynchronizeConfiguration)
    {
        var str = ""
        switch display {
        case .list_remote_files:
            if config.offsiteServer.isEmpty == false {
                if let arguments = ArgumentsRemoteFileList(config: config).remotefilelistarguments() {
                    str = (GetfullpathforRsync().rsyncpath() ?? "no rsync in path ") + " " + arguments.joined(separator: " ")
                }
            } else {
                str = NSLocalizedString("Use macOS Finder", comment: "")
            }
        case .create_public_SSHkey:
            if config.offsiteServer.isEmpty == false {
                let createsshkeys = SSHCreateKey(sharedsshport: String(SharedReference.shared.sshport ?? -1),
                                                 sharedsshkeypathandidentityfile: SharedReference.shared.sshkeypathandidentityfile)
                if let arguments = createsshkeys.argumentscreatekey() {
                    str = createsshkeys.createkeycommand + " " + arguments.joined(separator: " ")
                }
            } else {
                str = NSLocalizedString("No remote server on task", comment: "")
            }
        case .verify_public_SSHkey:
            if config.offsiteServer.isEmpty == false {
                let createsshkeys = SSHCreateKey(sharedsshport: String(SharedReference.shared.sshport ?? -1),
                                                 sharedsshkeypathandidentityfile: SharedReference.shared.sshkeypathandidentityfile)
                str = createsshkeys.argumentsverifyremotepublicsshkey(offsiteServer: config.offsiteServer, offsiteUsername: config.offsiteUsername)
            } else {
                str = NSLocalizedString("No remote server on task", comment: "")
            }
        case .copy_public_SSHkey:
            if config.offsiteServer.isEmpty == false {
                let createsshkeys = SSHCreateKey(sharedsshport: String(SharedReference.shared.sshport ?? -1),
                                                 sharedsshkeypathandidentityfile: SharedReference.shared.sshkeypathandidentityfile)
                str = createsshkeys.argumentssshcopyid(offsiteServer: config.offsiteServer, offsiteUsername: config.offsiteUsername)
            } else {
                str = NSLocalizedString("No remote server on task", comment: "")
            }
        case .remote_disk_usage:
            if config.offsiteServer.isEmpty == false {
                let diskusage = ArgumentsRemoteDiskUsage(config: config,
                                                         remotecatalog: config.offsiteCatalog)
                if let arguments = diskusage.argumentsremotediskusage() {
                    str = (diskusage.getCommand() ?? "") + " " + arguments.joined(separator: " ")
                }
            } else {
                str = NSLocalizedString("Use macOS Finder", comment: "")
            }
        case .push_data_to_remote_server:
            if config.offsiteServer.isEmpty == false {
                if let arguments = ArgumentsSynchronize(config: config).argumentsforpushlocaltoremote(dryRun: true,
                                                                                                      forDisplay: true) {
                    str = (GetfullpathforRsync().rsyncpath() ?? "no rsync in path ") + " " + arguments.joined(separator: " ")
                }
            } else {
                str = NSLocalizedString("No remote server on task", comment: "")
            }
        case .pull_data_from_remote_server:
            if config.offsiteServer.isEmpty == false {
                if let arguments = ArgumentsPullRemote(config: config).argumentspullremotewithparameters(dryRun: true,
                                                                                                      forDisplay: true) {
                    str = (GetfullpathforRsync().rsyncpath() ?? "no rsync in path ") + " " + arguments.joined(separator: " ")
                }
            } else {
                str = NSLocalizedString("No remote server on task", comment: "")
            }
        }
        command = str
    }
}

// swiftlint:enable line_length opening_brace
