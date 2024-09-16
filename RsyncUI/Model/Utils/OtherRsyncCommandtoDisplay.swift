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
    case synchronize
    case restore
    case verify
    case listfiles
    case create_sshkeys
    case check_remotepubkey

    var id: String { rawValue }
    var description: String { rawValue.localizedCapitalized }
}

@MainActor
struct OtherRsyncCommandtoDisplay {
    var command: String?

    init(display: OtherRsyncCommand,
         config: SynchronizeConfiguration)
    {
        var str = ""
        switch display {
        case .synchronize:
            if let arguments = ArgumentsSynchronize(config: config).argumentssynchronize(dryRun: true, forDisplay: true) {
                str = (GetfullpathforRsync().rsyncpath() ?? "no rsync in path ") + " " + arguments.joined()
            }
        case .restore:
            if let arguments = ArgumentsRestore(config: config, restoresnapshotbyfiles: false).argumentsrestore(dryRun: true, forDisplay: true) {
                str = (GetfullpathforRsync().rsyncpath() ?? "no rsync in path ") + " " + arguments.joined()
            }
        case .verify:
            if let arguments = ArgumentsVerify(config: config).argumentsverify(forDisplay: true) {
                str = (GetfullpathforRsync().rsyncpath() ?? "no rsync in path ") + " " + arguments.joined()
            }
        case .listfiles:
            str = (GetfullpathforRsync().rsyncpath() ?? "no rsync in path ") + " "
            if let arguments = ArgumentsRemoteFileList(config: config).remotefilelistarguments() {
                for i in 0 ..< arguments.count {
                    str += arguments[i] + " "
                }
            }
        case .create_sshkeys:
            let createsshkeys = SSHCreateKey(sharedsshport: String(SharedReference.shared.sshport ?? -1),
                                             sharedsshkeypathandidentityfile: SharedReference.shared.sshkeypathandidentityfile)
            if let arguments = createsshkeys.argumentscreatekey() {
                str = createsshkeys.createkeycommand + " "
                for i in 0 ..< arguments.count {
                    str += arguments[i] + " "
                }
            }
        case .check_remotepubkey:
            let createsshkeys = SSHCreateKey(sharedsshport: String(SharedReference.shared.sshport ?? -1),
                                             sharedsshkeypathandidentityfile: SharedReference.shared.sshkeypathandidentityfile)
            str = createsshkeys.argumentscheckremotepubkey(offsiteServer: config.offsiteServer, offsiteUsername: config.offsiteUsername)
        }
        command = str
    }
}

// swiftlint:enable line_length opening_brace

