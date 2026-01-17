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
    trailingSlash: TrailingSlash = .add,
    username: String? = nil,
    server: String? = nil,
    backupID: String? = "TestBackup"
) -> NewTask {
    NewTask(
        task,
        localCatalog,
        offsiteCatalog,
        trailingSlash,
        username,
        server,
        backupID
    )
}

@MainActor
@Suite("Configuration Validation Tests", .serialized)
struct VerifyConfigurationTests {
    // MARK: - Valid Configuration Tests

    @Test("Valid local synchronization configuration")
    func validLocalSynchronization() async {
        let task = makeValidTask()
        let verifier = VerifyConfiguration()

        let result = verifier.verify(task)

        #expect(result != nil)
        #expect(result?.task == "synchronize")
        #expect(result?.localCatalog == "/Users/test/Documents/")
        #expect(result?.offsiteCatalog == "/backup/Documents/")
        #expect(result?.backupID == "TestBackup")
        #expect(result?.offsiteServer == "")
        #expect(result?.offsiteUsername == "")
    }

    @Test("Valid remote synchronization with SSH")
    func validRemoteSynchronization() async {
        let task = makeValidTask(
            username: "testuser",
            server: "testserver.local"
        )
        let verifier = VerifyConfiguration()

        let result = verifier.verify(task)

        #expect(result != nil)
        #expect(result?.offsiteUsername == "testuser")
        #expect(result?.offsiteServer == "testserver.local")
    }

    @Test("Valid syncremote task")
    func validSyncremoteTask() async {
        SharedReference.shared.rsyncversion3 = true

        let task = makeValidTask(
            task: "syncremote",
            username: "testuser",
            server: "testserver.local"
        )
        let verifier = VerifyConfiguration()

        let result = verifier.verify(task)

        #expect(result != nil)
        #expect(result?.task == "syncremote")
    }

    // MARK: - Missing Catalog Tests

    @Test("Reject empty local catalog")
    func rejectEmptyLocalCatalog() async {
        let task = makeValidTask(localCatalog: "")
        let verifier = VerifyConfiguration()

        let result = verifier.verify(task)

        #expect(result == nil, "Should reject configuration with empty local catalog")
    }

    @Test("Reject empty remote catalog")
    func rejectEmptyRemoteCatalog() async {
        let task = makeValidTask(offsiteCatalog: "")
        let verifier = VerifyConfiguration()

        let result = verifier.verify(task)

        #expect(result == nil, "Should reject configuration with empty remote catalog")
    }

    @Test("Reject both catalogs empty")
    func rejectBothCatalogsEmpty() async {
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
    func rejectServerWithoutUsername() async {
        let task = makeValidTask(
            username: nil,
            server: "testserver.local"
        )
        let verifier = VerifyConfiguration()

        let result = verifier.verify(task)

        #expect(result == nil, "Should reject server configuration without username")
    }

    @Test("Reject username without server")
    func rejectUsernameWithoutServer() async {
        let task = makeValidTask(
            username: "testuser",
            server: nil
        )
        let verifier = VerifyConfiguration()

        let result = verifier.verify(task)

        #expect(result == nil, "Should reject username configuration without server")
    }

    @Test("Reject empty server with username")
    func rejectEmptyServerWithUsername() async {
        let task = makeValidTask(
            username: "testuser",
            server: ""
        )
        let verifier = VerifyConfiguration()

        let result = verifier.verify(task)

        #expect(result == nil, "Should reject empty server with username provided")
    }

    @Test("Reject empty username with server")
    func rejectEmptyUsernameWithServer() async {
        let task = makeValidTask(
            username: "",
            server: "testserver.local"
        )
        let verifier = VerifyConfiguration()

        let result = verifier.verify(task)

        #expect(result == nil, "Should reject empty username with server provided")
    }

    // MARK: - Trailing Slash Handling Tests

    @Test("Add trailing slash when specified")
    func addTrailingSlash() async {
        let task = makeValidTask(
            localCatalog: "/Users/test/Documents",
            offsiteCatalog: "/backup/Documents",
            trailingSlash: .add
        )
        let verifier = VerifyConfiguration()

        let result = verifier.verify(task)

        #expect(result != nil)
        #expect(result?.localCatalog.hasSuffix("/") == true, "Local catalog should have trailing slash")
        #expect(result?.offsiteCatalog.hasSuffix("/") == true, "Offsite catalog should have trailing slash")
    }

    @Test("Remove trailing slash when do_not_add")
    func removeTrailingSlash() async {
        let task = makeValidTask(
            localCatalog: "/Users/test/Documents/",
            offsiteCatalog: "/backup/Documents/",
            trailingSlash: .do_not_add
        )
        let verifier = VerifyConfiguration()

        let result = verifier.verify(task)

        #expect(result != nil)
        #expect(result?.localCatalog.hasSuffix("/") == false, "Local catalog should not have trailing slash")
        #expect(result?.offsiteCatalog.hasSuffix("/") == false, "Offsite catalog should not have trailing slash")
        #expect(result?.localCatalog == "/Users/test/Documents")
        #expect(result?.offsiteCatalog == "/backup/Documents")
    }

    @Test("Preserve paths with do_not_check")
    func preservePathsNoCheck() async {
        let task = makeValidTask(
            localCatalog: "/Users/test/Documents",
            offsiteCatalog: "/backup/Documents/",
            trailingSlash: .do_not_check
        )
        let verifier = VerifyConfiguration()

        let result = verifier.verify(task)

        #expect(result != nil)
        #expect(result?.localCatalog == "/Users/test/Documents", "Should preserve local catalog as-is")
        #expect(result?.offsiteCatalog == "/backup/Documents/", "Should preserve offsite catalog as-is")
    }

    @Test("Handle already present trailing slash with add option")
    func handleExistingTrailingSlashWithAdd() async {
        let task = makeValidTask(
            localCatalog: "/Users/test/Documents/",
            offsiteCatalog: "/backup/Documents/",
            trailingSlash: .add
        )
        let verifier = VerifyConfiguration()

        let result = verifier.verify(task)

        #expect(result != nil)
        #expect(result?.localCatalog == "/Users/test/Documents/", "Should not double-add trailing slash")
        #expect(result?.offsiteCatalog == "/backup/Documents/", "Should not double-add trailing slash")
    }

    // MARK: - Snapshot Validation Tests

    @Test("Reject snapshot task without rsync version 3")
    func rejectSnapshotWithoutVersion3() async {
        SharedReference.shared.rsyncversion3 = false

        let task = makeValidTask(
            task: "snapshot",
            username: "testuser",
            server: "localhost"
        )
        let verifier = VerifyConfiguration()

        let result = verifier.verify(task)

        #expect(result == nil, "Should reject snapshot task without rsync v3")
    }
}
