//
//  OtherRsyncCommandtoDisplay.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 16/09/2024.
//

import Foundation
import SSHCreateKey

enum OtherRsyncCommand: String, CaseIterable, Identifiable, CustomStringConvertible {
    case listRemoteFiles
    case createPublicSSHkey
    case copyPublicSSHkey
    case verifyPublicSSHkey
    // case remoteDiskUsage
    // case urlEstimate

    var id: String { rawValue }

    var description: String {
        // First handle special cases like SSH and URL
        let withSpecialCases = rawValue
            .replacingOccurrences(of: "SSH", with: "Ssh")
            .replacingOccurrences(of: "URL", with: "Url")

        // Then insert spaces before capitals
        let result = withSpecialCases.replacingOccurrences(
            of: "([A-Z])",
            with: " $1",
            options: .regularExpression
        ).trimmingCharacters(in: .whitespaces)

        // Capitalize first letter and fix acronyms back to uppercase
        let capitalized = result.prefix(1).uppercased() + result.dropFirst()
        return capitalized
            .replacingOccurrences(of: "Ssh", with: "SSH")
            .replacingOccurrences(of: "Url", with: "URL")
    }
}

@MainActor
struct OtherRsyncCommandtoDisplay {
    var command: String

    init(display: OtherRsyncCommand,
         config: SynchronizeConfiguration) {
        let str: [String] = switch display {
        case .listRemoteFiles:
            Self.listRemoteFiles(config: config)
        case .createPublicSSHkey:
            Self.createPublicSSHKey(config: config)
        case .verifyPublicSSHkey:
            Self.verifyPublicSSHKey(config: config)
        case .copyPublicSSHkey:
            Self.copyPublicSSHKey(config: config)
        }
        command = str.joined(separator: ",").replacingOccurrences(of: ",", with: " ")
    }

    private static func listRemoteFiles(config: SynchronizeConfiguration) -> [String] {
        if config.offsiteServer.isEmpty == false {
            if let arguments = ArgumentsRemoteFileList(config: config).remotefilelistarguments() {
                let rsyncPath = GetfullpathforRsync().rsyncpath()
                let cleanedArguments = arguments.joined(separator: " ").replacingOccurrences(of: ",", with: " ")
                return [rsyncPath, cleanedArguments]
            }
        } else {
            return ["Use macOS Finder"]
        }
        return []
    }

    private static func createPublicSSHKey(config: SynchronizeConfiguration) -> [String] {
        if config.offsiteServer.isEmpty == false {
            var sshcreatekeys: SSHCreateKey?
            let sshport = SharedReference.shared.sshport
            let sshkeypathandidentityfile = SharedReference.shared.sshkeypathandidentityfile

            if let port = sshport, let keypath = sshkeypathandidentityfile {
                // Both values are not nil
                sshcreatekeys = SSHCreateKey(sharedSSHPort: String(port),
                                             sharedSSHKeyPathAndIdentityFile: keypath)
            } else if let port = sshport {
                // Only port is not nil
                sshcreatekeys = SSHCreateKey(sharedSSHPort: String(port),
                                             sharedSSHKeyPathAndIdentityFile: nil)
            } else if let keypath = sshkeypathandidentityfile {
                // Only keypath is not nil
                sshcreatekeys = SSHCreateKey(sharedSSHPort: nil,
                                             sharedSSHKeyPathAndIdentityFile: keypath)
            }
            guard let sshcreatekeys else {
                return ["No SSH key configuration"]
            }
            let arguments = (try? sshcreatekeys.argumentsCreateKey()) ?? []
            let cleanedArguments = arguments.joined(separator: " ").replacingOccurrences(of: ",", with: " ")
            let createCmd = sshcreatekeys.createKeyCommand
            return [createCmd, cleanedArguments]
        } else {
            return ["No remote server on task"]
        }
    }

    private static func verifyPublicSSHKey(config: SynchronizeConfiguration) -> [String] {
        if config.offsiteServer.isEmpty == false {
            var sshcreatekeys: SSHCreateKey?
            let sshport = SharedReference.shared.sshport
            let sshkeypathandidentityfile = SharedReference.shared.sshkeypathandidentityfile

            if let port = sshport, let keypath = sshkeypathandidentityfile {
                // Both values are not nil
                sshcreatekeys = SSHCreateKey(sharedSSHPort: String(port),
                                             sharedSSHKeyPathAndIdentityFile: keypath)
            } else if let port = sshport {
                // Only port is not nil
                sshcreatekeys = SSHCreateKey(sharedSSHPort: String(port),
                                             sharedSSHKeyPathAndIdentityFile: nil)
            } else if let keypath = sshkeypathandidentityfile {
                // Only keypath is not nil
                sshcreatekeys = SSHCreateKey(sharedSSHPort: nil,
                                             sharedSSHKeyPathAndIdentityFile: keypath)
            }
            guard let sshcreatekeys else {
                return ["No SSH key configuration"]
            }
            let arguments = (try? sshcreatekeys.argumentsVerifyRemotePublicSSHKey(offsiteServer: config.offsiteServer, offsiteUsername: config.offsiteUsername)) ?? []
            let cleanedArguments = arguments.joined(separator: " ").replacingOccurrences(of: ",", with: " ")
            let createCmd = sshcreatekeys.createKeyCommand
            return [createCmd, cleanedArguments]
        } else {
            return ["No remote server on task"]
        }
    }

    private static func copyPublicSSHKey(config: SynchronizeConfiguration) -> [String] {
        if config.offsiteServer.isEmpty == false {
            var sshcreatekeys: SSHCreateKey?
            let sshport = SharedReference.shared.sshport
            let sshkeypathandidentityfile = SharedReference.shared.sshkeypathandidentityfile

            if let port = sshport, let keypath = sshkeypathandidentityfile {
                // Both values are not nil
                sshcreatekeys = SSHCreateKey(sharedSSHPort: String(port),
                                             sharedSSHKeyPathAndIdentityFile: keypath)
            } else if let port = sshport {
                // Only port is not nil
                sshcreatekeys = SSHCreateKey(sharedSSHPort: String(port),
                                             sharedSSHKeyPathAndIdentityFile: nil)
            } else if let keypath = sshkeypathandidentityfile {
                // Only keypath is not nil
                sshcreatekeys = SSHCreateKey(sharedSSHPort: nil,
                                             sharedSSHKeyPathAndIdentityFile: keypath)
            }
            guard let sshcreatekeys else {
                return ["No SSH key configuration"]
            }
            let arguments = (try? sshcreatekeys.argumentsSSHCopyID(offsiteServer: config.offsiteServer, offsiteUsername: config.offsiteUsername)) ?? []
            let cleanedArguments = arguments.joined(separator: " ").replacingOccurrences(of: ",", with: " ")
            let createCmd = sshcreatekeys.createKeyCommand
            return [createCmd, cleanedArguments]
        } else {
            return ["No remote server on task"]
        }
    }

    private static func urlEstimate(profile: String?) -> [String] {
        let deeplinkurl = DeeplinkURL()
        let urlestimate = deeplinkurl.createURLestimateandsynchronize(valueprofile: profile)
        return [urlestimate?.absoluteString ?? ""]
    }
}
