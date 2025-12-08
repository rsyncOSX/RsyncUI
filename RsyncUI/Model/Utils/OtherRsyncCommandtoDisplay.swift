//
//  OtherRsyncCommandtoDisplay.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 16/09/2024.
//

import Foundation
import SSHCreateKey

enum OtherRsyncCommand: String, CaseIterable, Identifiable, CustomStringConvertible {
    case list_remote_files
    case create_public_SSHkey
    case copy_public_SSHkey
    case verify_public_SSHkey
    // case remote_disk_usage
    case URL_estimate

    var id: String { rawValue }
    var description: String { rawValue.localizedCapitalized.replacingOccurrences(of: "_", with: " ") }
}

@MainActor
struct OtherRsyncCommandtoDisplay {
    var command: String

    init(display: OtherRsyncCommand,
         config: SynchronizeConfiguration,
         profile: String?) {
        let str: [String]
        switch display {
        case .list_remote_files:
            str = Self.listRemoteFiles(config: config)
        case .create_public_SSHkey:
            str = Self.createPublicSSHKey(config: config)
        case .verify_public_SSHkey:
            str = Self.verifyPublicSSHKey(config: config)
        case .copy_public_SSHkey:
            str = Self.copyPublicSSHKey(config: config)
        case .URL_estimate:
            str = Self.urlEstimate(profile: profile)
        }
        command = str.joined(separator: ",")
    }

    private static func listRemoteFiles(config: SynchronizeConfiguration) -> [String] {
        if config.offsiteServer.isEmpty == false {
            if let arguments = ArgumentsRemoteFileList(config: config).remotefilelistarguments() {
                let rsyncPath = GetfullpathforRsync().rsyncpath()
                let cleanedArguments = arguments.joined(separator: " ").replacingOccurrences(of: ",", with: "")
                return [rsyncPath, cleanedArguments]
            }
        } else {
            return ["Use macOS Finder"]
        }
        return []
    }

    private static func createPublicSSHKey(config: SynchronizeConfiguration) -> [String] {
        if config.offsiteServer.isEmpty == false {
            let createsshkeys = SSHCreateKey(sharedSSHPort: String(SharedReference.shared.sshport ?? -1),
                                             sharedSSHKeyPathAndIdentityFile: SharedReference.shared.sshkeypathandidentityfile)
            do {
                let arguments = try createsshkeys.argumentsCreateKey()
                let cleanedArguments = arguments.joined(separator: " ").replacingOccurrences(of: ",", with: "")
                return [createsshkeys.createKeyCommand, cleanedArguments]
            } catch {}
        } else {
            return ["No remote server on task"]
        }
        return []
    }

    private static func verifyPublicSSHKey(config: SynchronizeConfiguration) -> [String] {
        if config.offsiteServer.isEmpty == false {
            let createsshkeys = SSHCreateKey(sharedSSHPort: String(SharedReference.shared.sshport ?? -1),
                                             sharedSSHKeyPathAndIdentityFile: SharedReference.shared.sshkeypathandidentityfile)
            do {
                let tmpstr = try createsshkeys.argumentsVerifyRemotePublicSSHKey(offsiteServer: config.offsiteServer, offsiteUsername: config.offsiteUsername)
                let cleanedArguments = tmpstr.joined(separator: " ").replacingOccurrences(of: ",", with: "")
                return [cleanedArguments]
            } catch {}
        } else {
            return ["No remote server on task"]
        }
        return []
    }

    private static func copyPublicSSHKey(config: SynchronizeConfiguration) -> [String] {
        if config.offsiteServer.isEmpty == false {
            let createsshkeys = SSHCreateKey(sharedSSHPort: String(SharedReference.shared.sshport ?? -1),
                                             sharedSSHKeyPathAndIdentityFile: SharedReference.shared.sshkeypathandidentityfile)
            do {
                let tmpstr = try createsshkeys.argumentsSSHCopyID(offsiteServer: config.offsiteServer, offsiteUsername: config.offsiteUsername)
                let cleanedArguments = tmpstr.joined(separator: " ").replacingOccurrences(of: ",", with: "")
                return [cleanedArguments]
            } catch {}
        } else {
            return ["No remote server on task"]
        }
        return []
    }

    private static func urlEstimate(profile: String?) -> [String] {
        let deeplinkurl = DeeplinkURL()
        let urlestimate = deeplinkurl.createURLestimateandsynchronize(valueprofile: profile)
        return [urlestimate?.absoluteString ?? ""]
    }
}
