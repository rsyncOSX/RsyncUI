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
@Suite("Configuration Advanced Validation Tests", .serialized)
struct VerifyConfigurationAdvancedTests {
    // MARK: - Syncremote Validation Tests

    @Test("Reject syncremote without rsync version 3")
    func rejectSyncremoteWithoutVersion3() async {
        SharedReference.shared.rsyncversion3 = false

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
    func rejectSyncremoteWithoutServer() async {
        SharedReference.shared.rsyncversion3 = true

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
    func rejectSyncremoteWithoutUsername() async {
        SharedReference.shared.rsyncversion3 = true

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
    func handleNilBackupID() async {
        let task = makeValidTask(backupID: nil)
        let verifier = VerifyConfiguration()

        let result = verifier.verify(task)

        #expect(result != nil)
        #expect(result?.backupID == "", "Nil backup ID should become empty string")
    }

    @Test("Preserve backup ID")
    func preserveBackupID() async {
        let task = makeValidTask(backupID: "MyBackup-2024")
        let verifier = VerifyConfiguration()

        let result = verifier.verify(task)

        #expect(result != nil)
        #expect(result?.backupID == "MyBackup-2024")
    }

    @Test("Handle empty backup ID")
    func handleEmptyBackupID() async {
        let task = makeValidTask(backupID: "")
        let verifier = VerifyConfiguration()

        let result = verifier.verify(task)

        #expect(result != nil)
        #expect(result?.backupID == "")
    }

    @Test("Handle backup ID with special characters")
    func handleBackupIDWithSpecialCharacters() async {
        let specialIDs = [
            "backup_with_underscore",
            "backup-with-dash",
            "backup.with.dots",
            "backup123",
            "Backup With Spaces"
        ]

        let verifier = VerifyConfiguration()

        for specialID in specialIDs {
            let task = makeValidTask(backupID: specialID)
            let result = verifier.verify(task)

            #expect(result != nil, "Should accept backup ID: \(specialID)")
            #expect(result?.backupID == specialID, "Should preserve backup ID: \(specialID)")
        }
    }

    // MARK: - Hidden ID Tests

    @Test("Default hidden ID for new configuration")
    func defaultHiddenID() async {
        let task = makeValidTask()
        let verifier = VerifyConfiguration()

        let result = verifier.verify(task)

        #expect(result != nil)
        #expect(result?.hiddenID == -1, "New configurations should have hiddenID of -1")
    }

    @Test("Preserve hidden ID for updates")
    func preserveHiddenIDForUpdates() async {
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

        let result = verifier.verify(task)

        #expect(result != nil)
        #expect(result?.hiddenID == 42, "Should preserve hiddenID for configuration updates")
    }

    // MARK: - Edge Cases and Complex Scenarios

    @Test("Handle very long path names")
    func handleLongPaths() async {
        let longPath = "/Users/test/" + String(repeating: "very_long_folder_name/", count: 20)
        let task = makeValidTask(
            localCatalog: longPath,
            offsiteCatalog: longPath
        )
        let verifier = VerifyConfiguration()

        let result = verifier.verify(task)

        #expect(result != nil, "Should handle very long paths")
    }

    @Test("Handle paths with spaces")
    func handlePathsWithSpaces() async {
        let task = makeValidTask(
            localCatalog: "/Users/test/My Documents",
            offsiteCatalog: "/backup/My Documents"
        )
        let verifier = VerifyConfiguration()

        let result = verifier.verify(task)

        #expect(result != nil)
        #expect(result?.localCatalog.contains("My Documents") == true)
    }

    @Test("Handle paths with unicode characters")
    func handleUnicodePaths() async {
        let task = makeValidTask(
            localCatalog: "/Users/test/文档",
            offsiteCatalog: "/backup/文档"
        )
        let verifier = VerifyConfiguration()

        let result = verifier.verify(task)

        #expect(result != nil, "Should handle unicode characters in paths")
    }

    @Test("Trailing slash handling with various separators")
    func trailingSlashVariousSeparators() async {
        let paths = [
            "/simple/path",
            "/path/with/many/levels/deep",
            "/path/",
            "relative/path"
        ]

        let verifier = VerifyConfiguration()

        for path in paths {
            let task = makeValidTask(
                localCatalog: path,
                offsiteCatalog: path,
                trailingSlash: .add
            )
            let result = verifier.verify(task)

            #expect(result != nil, "Should handle path: \(path)")
            #expect(result?.localCatalog.hasSuffix("/") == true, "Path should have trailing slash: \(path)")
        }
    }

    // MARK: - Parameter Preservation Tests

    @Test("Initialize with default parameter values")
    func initializeDefaultParameters() async {
        let task = makeValidTask()
        let verifier = VerifyConfiguration()

        let result = verifier.verify(task)

        #expect(result != nil)
        #expect(result?.parameter4 == nil, "parameter4 should be nil by default")
        #expect(result?.dateRun == "", "dateRun should be empty by default")
        #expect(result?.halted == 0, "halted should be 0 by default")
    }
}
