//
//  ShortcutsApproval.swift
//  RsyncUI
//
//  A task may only be synchronized from Shortcuts after the user has verified
//  it in the Verify tab and allowed it. The approval is a fingerprint of the
//  settings that decide what rsync does, so editing any of them revokes it.
//

import CryptoKit
import Foundation

extension SynchronizeConfiguration {
    /// SHA-256 of the settings that decide what rsync does. The task name, last
    /// run date, snapshot number and halted state are left out on purpose.
    var shortcutsFingerprint: String {
        let fields: [String] = [
            task,
            localCatalog,
            offsiteCatalog,
            offsiteUsername,
            offsiteServer,
            parameter4 ?? "",
            parameter8 ?? "",
            parameter9 ?? "",
            parameter10 ?? "",
            parameter11 ?? "",
            parameter12 ?? "",
            parameter13 ?? "",
            parameter14 ?? "",
            rsyncdaemon.map(String.init) ?? "",
            sshport.map(String.init) ?? "",
            sshkeypathandidentityfile ?? ""
        ]
        // Unit separator, so values cannot run into each other
        let digest = SHA256.hash(data: Data(fields.joined(separator: "\u{1F}").utf8))
        return digest.map { String(format: "%02x", $0) }.joined()
    }

    /// True if the user allowed this task in Shortcuts and has not changed its
    /// settings since.
    var isAllowedInShortcuts: Bool {
        guard let shortcutsapproval else { return false }
        return shortcutsapproval == shortcutsFingerprint
    }
}
