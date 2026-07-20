//
//  VerifyConfigurationTests.swift
//  RsyncUITests
//
//  Created by Thomas Evensen on 18/12/2025.
//

import Foundation
@testable import RsyncUI
import Testing

// MARK: - Shared Test Helpers

/// Shared helper for creating test configurations
func makeValidTask(
    task: String = "synchronize",
    localCatalog: String = "/Users/test/Documents",
    offsiteCatalog: String = "/backup/Documents",
    username: String? = nil,
    server: String? = nil,
    backupID: String? = "TestBackup"
) -> NewTask {
    NewTask(
        task,
        localCatalog,
        offsiteCatalog,
        username,
        server,
        backupID
    )
}

@MainActor
@Suite(.serialized, .tags(.validation))
struct VerifyConfigurationTests {
    // MARK: - Valid Configuration Tests

    @Test("Valid local synchronization configuration")
    func validLocalSynchronization() throws {
        let task = makeValidTask()
        let verifier = VerifyConfiguration()

        let result = try #require(verifier.verify(task))

        #expect(result.task == "synchronize")
        #expect(result.localCatalog == "/Users/test/Documents")
        #expect(result.offsiteCatalog == "/backup/Documents")
        #expect(result.backupID == "TestBackup")
        #expect(result.offsiteServer == "")
        #expect(result.offsiteUsername == "")
    }

    @Test("Valid remote synchronization with SSH")
    func validRemoteSynchronization() throws {
        let task = makeValidTask(
            username: "testuser",
            server: "testserver.local"
        )
        let verifier = VerifyConfiguration()

        let result = try #require(verifier.verify(task))

        #expect(result.offsiteUsername == "testuser")
        #expect(result.offsiteServer == "testserver.local")
    }

    @Test("Valid syncremote task")
    func validSyncremoteTask() throws {
        let originalVersion = SharedReference.shared.rsyncversion3
        SharedReference.shared.rsyncversion3 = true
        defer { SharedReference.shared.rsyncversion3 = originalVersion }

        let task = makeValidTask(
            task: "syncremote",
            username: "testuser",
            server: "testserver.local"
        )
        let verifier = VerifyConfiguration()

        let result = try #require(verifier.verify(task))

        #expect(result.task == "syncremote")
    }

    // MARK: - Missing Catalog Tests

    @Test("Reject empty local catalog")
    func rejectEmptyLocalCatalog() {
        let task = makeValidTask(localCatalog: "")
        let verifier = VerifyConfiguration()

        let result = verifier.verify(task)

        #expect(result == nil, "Should reject configuration with empty local catalog")
    }

    @Test("Reject empty remote catalog")
    func rejectEmptyRemoteCatalog() {
        let task = makeValidTask(offsiteCatalog: "")
        let verifier = VerifyConfiguration()

        let result = verifier.verify(task)

        #expect(result == nil, "Should reject configuration with empty remote catalog")
    }

    @Test("Reject both catalogs empty")
    func rejectBothCatalogsEmpty() {
        let task = makeValidTask(
            localCatalog: "",
            offsiteCatalog: ""
        )
        let verifier = VerifyConfiguration()

        let result = verifier.verify(task)

        #expect(result == nil, "Should reject configuration with both catalogs empty")
    }

    // MARK: - SSH Configuration Validation Tests

    @Test("Reject server without username")
    func rejectServerWithoutUsername() {
        let task = makeValidTask(
            username: nil,
            server: "testserver.local"
        )
        let verifier = VerifyConfiguration()

        let result = verifier.verify(task)

        #expect(result == nil, "Should reject server configuration without username")
    }

    @Test("Reject username without server")
    func rejectUsernameWithoutServer() {
        let task = makeValidTask(
            username: "testuser",
            server: nil
        )
        let verifier = VerifyConfiguration()

        let result = verifier.verify(task)

        #expect(result == nil, "Should reject username configuration without server")
    }

    @Test("Reject empty server with username")
    func rejectEmptyServerWithUsername() {
        let task = makeValidTask(
            username: "testuser",
            server: ""
        )
        let verifier = VerifyConfiguration()

        let result = verifier.verify(task)

        #expect(result == nil, "Should reject empty server with username provided")
    }

    @Test("Reject empty username with server")
    func rejectEmptyUsernameWithServer() {
        let task = makeValidTask(
            username: "",
            server: "testserver.local"
        )
        let verifier = VerifyConfiguration()

        let result = verifier.verify(task)

        #expect(result == nil, "Should reject empty username with server provided")
    }

    // MARK: - Catalog Path Preservation Tests

    @Test("Preserve catalog paths without trailing slashes")
    func preserveCatalogPathsWithoutTrailingSlashes() throws {
        let task = makeValidTask(
            localCatalog: "/Users/test/Documents",
            offsiteCatalog: "/backup/Documents"
        )
        let verifier = VerifyConfiguration()

        let result = try #require(verifier.verify(task))

        #expect(result.localCatalog == "/Users/test/Documents")
        #expect(result.offsiteCatalog == "/backup/Documents")
    }

    @Test("Preserve catalog paths with trailing slashes")
    func preserveCatalogPathsWithTrailingSlashes() throws {
        let task = makeValidTask(
            localCatalog: "/Users/test/Documents/",
            offsiteCatalog: "/backup/Documents/"
        )
        let verifier = VerifyConfiguration()

        let result = try #require(verifier.verify(task))

        #expect(result.localCatalog == "/Users/test/Documents/")
        #expect(result.offsiteCatalog == "/backup/Documents/")
    }

    // MARK: - Snapshot Validation Tests

    @Test("Reject snapshot task without rsync version 3")
    func rejectSnapshotWithoutVersion3() {
        let originalVersion = SharedReference.shared.rsyncversion3
        SharedReference.shared.rsyncversion3 = false
        defer { SharedReference.shared.rsyncversion3 = originalVersion }

        let task = makeValidTask(
            task: "snapshot",
            username: "testuser",
            server: "localhost"
        )
        let verifier = VerifyConfiguration()

        let result = verifier.verify(task)

        #expect(result == nil, "Should reject snapshot task without rsync v3")
    }

    @Test("Snapshot task defaults snapshotnum to 1 when missing")
    func snapshotDefaultsSnapshotNum() throws {
        let originalVersion = SharedReference.shared.rsyncversion3
        SharedReference.shared.rsyncversion3 = true
        defer { SharedReference.shared.rsyncversion3 = originalVersion }

        var task = makeValidTask(task: "snapshot")
        task.snapshotnum = nil
        let verifier = VerifyConfiguration()

        let result = try #require(verifier.verify(task))

        #expect(result.snapshotnum == 1, "Snapshot should default snapshotnum to 1")
    }

    @Test("Snapshot task preserves explicit snapshotnum")
    func snapshotPreservesSnapshotNum() throws {
        let originalVersion = SharedReference.shared.rsyncversion3
        SharedReference.shared.rsyncversion3 = true
        defer { SharedReference.shared.rsyncversion3 = originalVersion }

        let task = NewTask(
            "snapshot",
            "/Users/test/Documents",
            "/backup/Documents",
            nil,
            nil,
            "TestBackup",
            1,
            3
        )
        let verifier = VerifyConfiguration()

        let result = try #require(verifier.verify(task))

        #expect(result.snapshotnum == 3, "Snapshot should preserve provided snapshotnum")
    }
}
