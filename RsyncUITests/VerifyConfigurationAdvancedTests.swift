//
//  VerifyConfigurationAdvancedTests.swift
//  RsyncUITests
//
//  Created by Thomas Evensen on 18/12/2025.
//

import Foundation
@testable import RsyncUI
import Testing

@MainActor
@Suite(.serialized, .tags(.validation))
struct VerifyConfigurationAdvancedTests {
    // MARK: - Syncremote Validation Tests

    @Test("Reject syncremote without rsync version 3")
    func rejectSyncremoteWithoutVersion3() {
        let originalVersion = SharedReference.shared.rsyncversion3
        SharedReference.shared.rsyncversion3 = false
        defer { SharedReference.shared.rsyncversion3 = originalVersion }

        let task = makeValidTask(
            task: "syncremote",
            username: "testuser",
            server: "testserver.local"
        )
        let verifier = VerifyConfiguration()

        let result = verifier.verify(task)

        #expect(result == nil, "Should reject syncremote task without rsync v3")
    }

    @Test("Reject syncremote without remote server")
    func rejectSyncremoteWithoutServer() {
        let originalVersion = SharedReference.shared.rsyncversion3
        SharedReference.shared.rsyncversion3 = true
        defer { SharedReference.shared.rsyncversion3 = originalVersion }

        let task = makeValidTask(
            task: "syncremote",
            username: "testuser",
            server: nil
        )
        let verifier = VerifyConfiguration()

        let result = verifier.verify(task)

        #expect(result == nil, "Should reject syncremote without remote server")
    }

    @Test("Reject syncremote without username")
    func rejectSyncremoteWithoutUsername() {
        let originalVersion = SharedReference.shared.rsyncversion3
        SharedReference.shared.rsyncversion3 = true
        defer { SharedReference.shared.rsyncversion3 = originalVersion }

        let task = makeValidTask(
            task: "syncremote",
            username: nil,
            server: "testserver.local"
        )
        let verifier = VerifyConfiguration()

        let result = verifier.verify(task)

        #expect(result == nil, "Should reject syncremote without username")
    }

    // MARK: - Backup ID Tests

    @Test("Handle nil backup ID")
    func handleNilBackupID() throws {
        let task = makeValidTask(backupID: nil)
        let verifier = VerifyConfiguration()

        let result = try #require(verifier.verify(task))

        #expect(result.backupID == "", "Nil backup ID should become empty string")
    }

    @Test("Preserve backup ID")
    func preserveBackupID() throws {
        let task = makeValidTask(backupID: "MyBackup-2024")
        let verifier = VerifyConfiguration()

        let result = try #require(verifier.verify(task))

        #expect(result.backupID == "MyBackup-2024")
    }

    @Test("Handle empty backup ID")
    func handleEmptyBackupID() throws {
        let task = makeValidTask(backupID: "")
        let verifier = VerifyConfiguration()

        let result = try #require(verifier.verify(task))

        #expect(result.backupID == "")
    }

    @Test(
        "Handle backup ID with special characters",
        arguments: [
            "backup_with_underscore",
            "backup-with-dash",
            "backup.with.dots",
            "backup123",
            "Backup With Spaces"
        ]
    )
    func handleBackupIDWithSpecialCharacters(_ specialID: String) throws {
        let verifier = VerifyConfiguration()

        let task = makeValidTask(backupID: specialID)
        let result = try #require(verifier.verify(task))

        #expect(result.backupID == specialID, "Should preserve backup ID: \(specialID)")
    }

    // MARK: - Hidden ID Tests

    @Test("Default hidden ID for new configuration")
    func defaultHiddenID() throws {
        let task = makeValidTask()
        let verifier = VerifyConfiguration()

        let result = try #require(verifier.verify(task))

        #expect(result.hiddenID == -1, "New configurations should have hiddenID of -1")
    }

    @Test("Preserve hidden ID for updates")
    func preserveHiddenIDForUpdates() throws {
        let task = NewTask(
            "synchronize",
            "/Users/test/Documents",
            "/backup/Documents",
            .add,
            nil,
            nil,
            "TestBackup",
            42, // hiddenID for update
            nil
        )
        let verifier = VerifyConfiguration()

        let result = try #require(verifier.verify(task))

        #expect(result.hiddenID == 42, "Should preserve hiddenID for configuration updates")
    }

    // MARK: - Edge Cases and Complex Scenarios

    @Test("Handle very long path names")
    func handleLongPaths() throws {
        let longPath = "/Users/test/" + String(repeating: "very_long_folder_name/", count: 20)
        let task = makeValidTask(
            localCatalog: longPath,
            offsiteCatalog: longPath
        )
        let verifier = VerifyConfiguration()

        let result = try #require(verifier.verify(task))

        #expect(result.localCatalog.hasPrefix("/Users/test/") == true, "Should handle very long paths")
    }

    @Test("Handle paths with spaces")
    func handlePathsWithSpaces() throws {
        let task = makeValidTask(
            localCatalog: "/Users/test/My Documents",
            offsiteCatalog: "/backup/My Documents"
        )
        let verifier = VerifyConfiguration()

        let result = try #require(verifier.verify(task))

        #expect(result.localCatalog.contains("My Documents") == true)
    }

    @Test("Handle paths with unicode characters")
    func handleUnicodePaths() throws {
        let task = makeValidTask(
            localCatalog: "/Users/test/文档",
            offsiteCatalog: "/backup/文档"
        )
        let verifier = VerifyConfiguration()

        let result = try #require(verifier.verify(task))

        #expect(result.localCatalog.contains("文档") == true, "Should handle unicode characters in paths")
    }

    @Test(
        "Trailing slash handling with various separators",
        arguments: [
            "/simple/path",
            "/path/with/many/levels/deep",
            "/path/",
            "relative/path"
        ]
    )
    func trailingSlashVariousSeparators(_ path: String) throws {
        let verifier = VerifyConfiguration()

        let task = makeValidTask(
            localCatalog: path,
            offsiteCatalog: path,
            trailingSlash: .add
        )
        let result = try #require(verifier.verify(task))

        #expect(result.localCatalog.hasSuffix("/") == true, "Path should have trailing slash: \(path)")
    }

    // MARK: - Parameter Preservation Tests

    @Test("Initialize with default parameter values")
    func initializeDefaultParameters() throws {
        let task = makeValidTask()
        let verifier = VerifyConfiguration()

        let result = try #require(verifier.verify(task))

        #expect(result.parameter4 == nil, "parameter4 should be nil by default")
        #expect(result.dateRun == "", "dateRun should be empty by default")
        #expect(result.halted == 0, "halted should be 0 by default")
    }
}
