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
    case URL_verify
    case URL_estimate
    

    var id: String { rawValue }
    var description: String { rawValue.localizedCapitalized.replacingOccurrences(of: "_", with: " ") }
}

@MainActor
struct OtherRsyncCommandtoDisplay {
    var command: String
    var profile: String = "Default"

    init(display: OtherRsyncCommand,
         config: SynchronizeConfiguration,
         profile: String?)
    {
        var str = ""
        if let profile {
            self.profile = profile
        }
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
        case .URL_verify:
            if config.task == SharedReference.shared.synchronize {
                let deeplinkurl = DeeplinkURL()

                if config.offsiteServer.isEmpty == false {
                    // Create verifyremote URL
                    let urlverify = deeplinkurl.createURLloadandverify(valueprofile: profile, valueid: config.backupID)
                    str = urlverify?.absoluteString ?? ""
                }
            } else {
                str = ""
            }
        case .URL_estimate:
            let deeplinkurl = DeeplinkURL()
            // Create estimate and synchronize URL
            let urlestimate = deeplinkurl.createURLestimateandsynchronize(valueprofile: profile)
            str = urlestimate?.absoluteString ?? ""
        }
        command = str
    }
}

// swiftlint:enable line_length opening_brace

