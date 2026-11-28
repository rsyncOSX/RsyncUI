//
//  ShortcutsApprovalTests.swift
//  RsyncUITests
//

import Foundation
@testable import RsyncUI
import Testing

@MainActor
@Suite("Shortcuts approval")
struct ShortcutsApprovalTests {
    func makeApprovedConfig() -> SynchronizeConfiguration {
        var config = SynchronizeConfiguration()
        config.hiddenID = 1
        config.task = "synchronize"
        config.localCatalog = "/Users/test/source/"
        config.offsiteCatalog = "/Users/test/dest/"
        config.parameter4 = "--delete"
        config.shortcutsapproval = config.shortcutsFingerprint
        return config
    }

    @Test("A task is not allowed until approved")
    func notApprovedByDefault() {
        var config = makeApprovedConfig()
        config.shortcutsapproval = nil
        #expect(config.isAllowedInShortcuts == false)
    }

    @Test("An approved task is allowed")
    func approvedIsAllowed() {
        #expect(makeApprovedConfig().isAllowedInShortcuts)
    }

    @Test("Changing what rsync does revokes the approval")
    func settingChangesRevoke() {
        var destination = makeApprovedConfig()
        destination.offsiteCatalog = "/Volumes/Other/"
        #expect(destination.isAllowedInShortcuts == false)

        var deletion = makeApprovedConfig()
        deletion.parameter4 = ""
        #expect(deletion.isAllowedInShortcuts == false)

        var server = makeApprovedConfig()
        server.offsiteServer = "raspberrypi"
        #expect(server.isAllowedInShortcuts == false)

        var ssh = makeApprovedConfig()
        ssh.sshport = 2222
        #expect(ssh.isAllowedInShortcuts == false)
    }

    @Test("Name, last run and snapshot number do not revoke the approval")
    func bookkeepingKeepsApproval() {
        var config = makeApprovedConfig()
        config.backupID = "Renamed"
        config.dateRun = "26 Nov 2026 08:18"
        config.snapshotnum = 42
        #expect(config.isAllowedInShortcuts)
    }

    @Test("Values cannot shift between fields")
    func fieldsAreSeparated() {
        var first = SynchronizeConfiguration()
        first.localCatalog = "/a"
        first.offsiteCatalog = "b/"
        var second = SynchronizeConfiguration()
        second.localCatalog = "/ab"
        second.offsiteCatalog = "/"
        #expect(first.shortcutsFingerprint != second.shortcutsFingerprint)
    }

    @Test("Allowing or revoking changes equality, so the task list redraws the row")
    func approvalChangesEquality() {
        let allowed = makeApprovedConfig()
        var revoked = allowed
        revoked.shortcutsapproval = nil
        #expect(allowed != revoked)
        #expect(allowed.hashValue != revoked.hashValue)
    }

    @Test("The approval survives saving and loading")
    func roundTrip() throws {
        let config = makeApprovedConfig()
        let data = try JSONEncoder().encode([config])
        let decoded = try JSONDecoder().decode([DecodeSynchronizeConfiguration].self, from: data)
        let loaded = SynchronizeConfiguration(decoded[0])
        #expect(loaded.isAllowedInShortcuts)
    }
}
