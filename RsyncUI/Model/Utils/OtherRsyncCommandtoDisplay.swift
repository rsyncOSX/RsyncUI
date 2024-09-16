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
    case listfiles
    case create_ssh_keys

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
        case .listfiles:
            str = (GetfullpathforRsync().rsyncpath() ?? "no rsync in path ") + " "
            if let arguments = ArgumentsRemoteFileList(config: config).remotefilelistarguments() {
                for i in 0 ..< arguments.count {
                    str += arguments[i] + " "
                }
            }
        case .create_ssh_keys:
            let createsshkeys = SSHCreateKey(sharedsshport: String(SharedReference.shared.sshport ?? -1),
                                             sharedsshkeypathandidentityfile: SharedReference.shared.sshkeypathandidentityfile)
            if let arguments = createsshkeys.argumentscreatekey() {
                str = createsshkeys.createkeycommand + " "
                for i in 0 ..< arguments.count {
                    str += arguments[i] + " "
                }
            }
        }
        command = str
    }
}

// swiftlint:enable line_length opening_brace

