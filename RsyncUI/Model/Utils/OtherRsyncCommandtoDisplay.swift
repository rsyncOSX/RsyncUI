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
    // case remote_disk_usage
    case URL_verify
    case URL_estimate

    var id: String { rawValue }
    var description: String { rawValue.localizedCapitalized.replacingOccurrences(of: "_", with: " ") }
}

@MainActor
struct OtherRsyncCommandtoDisplay {
    var command: String

    init(display: OtherRsyncCommand,
         config: SynchronizeConfiguration,
         profile: String?)
    {
        var str = [String]()
        switch display {
        case .list_remote_files:
            if config.offsiteServer.isEmpty == false {
                if let arguments = ArgumentsRemoteFileList(config: config).remotefilelistarguments() {
                    str.append(GetfullpathforRsync().rsyncpath() ?? "no rsync in path ")
                    let cleanedArguments = arguments.joined(separator: " ").replacingOccurrences(of: ",", with: "")
                    str.append(cleanedArguments)
                }
            } else {
                str = ["Use macOS Finder"]
            }
        case .create_public_SSHkey:
            if config.offsiteServer.isEmpty == false {
                let createsshkeys = SSHCreateKey(sharedSSHPort: String(SharedReference.shared.sshport ?? -1),
                                                 sharedSSHKeyPathAndIdentityFile: SharedReference.shared.sshkeypathandidentityfile)
                do {
                    let arguments = try createsshkeys.argumentsCreateKey()
                    str.append(createsshkeys.createKeyCommand)
                    let cleanedArguments = arguments.joined(separator: " ").replacingOccurrences(of: ",", with: "")
                    str.append(cleanedArguments)

                } catch {}

            } else {
                str = ["No remote server on task"]
            }
        case .verify_public_SSHkey:
            if config.offsiteServer.isEmpty == false {
                let createsshkeys = SSHCreateKey(sharedSSHPort: String(SharedReference.shared.sshport ?? -1),
                                                 sharedSSHKeyPathAndIdentityFile: SharedReference.shared.sshkeypathandidentityfile)
                do {
                    let tmpstr = try createsshkeys.argumentsVerifyRemotePublicSSHKey(offsiteServer: config.offsiteServer, offsiteUsername: config.offsiteUsername)
                    let cleanedArguments = tmpstr.joined(separator: " ").replacingOccurrences(of: ",", with: "")
                    str.append(cleanedArguments)
                } catch {}

            } else {
                str = ["No remote server on task"]
            }
        case .copy_public_SSHkey:
            if config.offsiteServer.isEmpty == false {
                let createsshkeys = SSHCreateKey(sharedSSHPort: String(SharedReference.shared.sshport ?? -1),
                                                 sharedSSHKeyPathAndIdentityFile: SharedReference.shared.sshkeypathandidentityfile)
                do {
                    let tmpstr = try createsshkeys.argumentsSSHCopyID(offsiteServer: config.offsiteServer, offsiteUsername: config.offsiteUsername)
                    let cleanedArguments = tmpstr.joined(separator: " ").replacingOccurrences(of: ",", with: "")
                    str.append(cleanedArguments)
                } catch {}
            } else {
                str = ["No remote server on task"]
            }
        case .URL_verify:
            if config.task == SharedReference.shared.synchronize {
                let deeplinkurl = DeeplinkURL()

                if config.offsiteServer.isEmpty == false {
                    // Create verifyremote URL
                    let urlverify = deeplinkurl.createURLloadandverify(valueprofile: profile, valueid: config.backupID)
                    str = [urlverify?.absoluteString ?? ""]
                }
            } else {
                str.removeAll()
            }
        case .URL_estimate:
            let deeplinkurl = DeeplinkURL()
            // Create estimate and synchronize URL
            let urlestimate = deeplinkurl.createURLestimateandsynchronize(valueprofile: profile)
            str = [urlestimate?.absoluteString ?? ""]
        }
        command = str.joined(separator: ",")
    }
}

// swiftlint:enable line_length opening_brace
