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
    case synchronize_data
    case restore_data
    case verify_synchronized_data
    case list_remote_files
    case create_public_SSHkey
    case copy_public_SSHkey
    case verify_public_SSHkey
    

    var id: String { rawValue }
    var description: String { rawValue.localizedCapitalized.replacingOccurrences(of: "_", with: " ") }
}

@MainActor
struct OtherRsyncCommandtoDisplay {
    var command: String?

    init(display: OtherRsyncCommand,
         config: SynchronizeConfiguration)
    {
        var str = ""
        switch display {
        case .synchronize_data:
            if let arguments = ArgumentsSynchronize(config: config).argumentssynchronize(dryRun: true, forDisplay: true) {
                str = (GetfullpathforRsync().rsyncpath() ?? "no rsync in path ") + " " + arguments.joined()
            }
        case .restore_data:
            if let arguments = ArgumentsRestore(config: config, restoresnapshotbyfiles: false).argumentsrestore(dryRun: true, forDisplay: true) {
                str = (GetfullpathforRsync().rsyncpath() ?? "no rsync in path ") + " " + arguments.joined()
            }
        case .verify_synchronized_data:
            if let arguments = ArgumentsVerify(config: config).argumentsverify(forDisplay: true) {
                str = (GetfullpathforRsync().rsyncpath() ?? "no rsync in path ") + " " + arguments.joined()
            }
        case .list_remote_files:
            str = (GetfullpathforRsync().rsyncpath() ?? "no rsync in path ") + " "
            if let arguments = ArgumentsRemoteFileList(config: config).remotefilelistarguments() {
                for i in 0 ..< arguments.count {
                    str += arguments[i] + " "
                }
            }
        case .create_public_SSHkey:
            let createsshkeys = SSHCreateKey(sharedsshport: String(SharedReference.shared.sshport ?? -1),
                                             sharedsshkeypathandidentityfile: SharedReference.shared.sshkeypathandidentityfile)
            if let arguments = createsshkeys.argumentscreatekey() {
                str = createsshkeys.createkeycommand + " "
                for i in 0 ..< arguments.count {
                    str += arguments[i] + " "
                }
            }
        case .verify_public_SSHkey:
            let createsshkeys = SSHCreateKey(sharedsshport: String(SharedReference.shared.sshport ?? -1),
                                             sharedsshkeypathandidentityfile: SharedReference.shared.sshkeypathandidentityfile)
            str = createsshkeys.argumentsverifyremotepublicsshkey(offsiteServer: config.offsiteServer, offsiteUsername: config.offsiteUsername)
        case .copy_public_SSHkey:
            let createsshkeys = SSHCreateKey(sharedsshport: String(SharedReference.shared.sshport ?? -1),
                                             sharedsshkeypathandidentityfile: SharedReference.shared.sshkeypathandidentityfile)
            str = createsshkeys.argumentssshcopyid(offsiteServer: config.offsiteServer, offsiteUsername: config.offsiteUsername)
        }
        command = str
    }
}

// swiftlint:enable line_length opening_brace

