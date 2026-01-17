//
//  RsyncUITests.swift
//  RsyncUITests
//
//  Created by Thomas Evensen on 18/12/2025.
//
/* swiftlint:disable all */
// xcodebuild -scheme RsyncUI -project RsyncUI.xcodeproj -destination 'platform=macOS' -only-testing:RsyncUITests test
import Foundation
import RsyncArguments
@testable import RsyncUI
import Testing

enum RsyncUITests {
    @MainActor
    @Suite("Arguments Generation Tests", .serialized)
    struct ArgumentsSynchronizeTests {
        func makeConfig(
            task: String = "synchronize",
            local: String = "/Users/test/Documents/",
            remote: String = "/backup/Documents/",
            username: String = "",
            server: String = ""
        ) -> SynchronizeConfiguration {
            var cfg = SynchronizeConfiguration()
            cfg.task = task
            cfg.localCatalog = local
            cfg.offsiteCatalog = remote
            cfg.offsiteUsername = username
            cfg.offsiteServer = server
            cfg.halted = 0
            return cfg
        }

        @Test("Synchronize returns dry-run args")
        func synchronizeDryRunArgs() async {
            SharedReference.shared.rsyncversion3 = true

            let cfg = makeConfig()
            let generator = ArgumentsSynchronize(config: cfg)
            let args = generator.argumentsSynchronize(dryRun: true, forDisplay: false)

            #expect(args != nil)
            // Accept either common dry-run flags
            #expect(args!.contains("--dry-run") || args!.contains("-n"))
        }

        /*
         @Test("Snapshot task produces arguments")
         func snapshotArgs() async {
             SharedReference.shared.rsyncversion3 = true

             var cfg = makeConfig(task: SharedReference.shared.snapshot,
                                  username: "testuser",
                                  server: "localhost")
             let generator = ArgumentsSynchronize(config: cfg)
             let args = generator.argumentsSynchronize(dryRun: false, forDisplay: false)

             #expect(args != nil)
         }
         */
        @Test("Syncremote task produces arguments")
        func syncremoteArgs() async {
            SharedReference.shared.rsyncversion3 = true

            let cfg = makeConfig(task: SharedReference.shared.syncremote,
                                 username: "testuser",
                                 server: "testserver.local")
            let generator = ArgumentsSynchronize(config: cfg)
            let args = generator.argumentsSynchronize(dryRun: true, forDisplay: false)

            #expect(args != nil)
        }

        @Test("Push local→remote with keepdelete variations")
        func pushLocalToRemoteArgs() async {
            SharedReference.shared.rsyncversion3 = true

            let cfg = makeConfig()
            let generator = ArgumentsSynchronize(config: cfg)

            let argsKeep = generator.argumentsforpushlocaltoremotewithparameters(dryRun: false,
                                                                                 forDisplay: false,
                                                                                 keepdelete: true)
            let argsNoKeep = generator.argumentsforpushlocaltoremotewithparameters(dryRun: false,
                                                                                   forDisplay: false,
                                                                                   keepdelete: false)

            #expect(argsKeep != nil)
            #expect(argsNoKeep != nil)
        }
    }

    @MainActor
    @Suite("Deeplink URL Tests", .serialized)
    struct DeeplinkURLTests {
        @Test("Create estimate-and-synchronize URL with default profile")
        func createURLDefaultProfile() async {
            let url = DeeplinkURL().createURLestimateandsynchronize(valueprofile: nil)
            #expect(url != nil)
            #expect(url!.absoluteString.contains("profile=Default"))
        }

        @Test("Create estimate-and-synchronize URL with custom profile")
        func createURLCustomProfile() async {
            let url = DeeplinkURL().createURLestimateandsynchronize(valueprofile: "Work")
            #expect(url != nil)
            #expect(url!.absoluteString.contains("profile=Work"))
        }
    }

    @MainActor
    @Suite("Configuration Validation Tests", .serialized)
    struct VerifyConfigurationTests {
        // MARK: - Test Helpers

        /// Creates a basic valid AppendTask for testing
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

        /*
         @Test("Valid snapshot task with version 3")
         func validSnapshotTask() async {
             // Setup: Enable rsync version 3
             SharedReference.shared.rsyncversion3 = true

             let task = makeValidTask(
                 task: "snapshot",
                 username: "testuser",
                 server: "localhost"  // Use localhost to avoid network checks
             )
             let verifier = VerifyConfiguration()

             let result = verifier.verify(task)

             #expect(result != nil)
             #expect(result?.task == "snapshot")
             #expect(result?.snapshotnum == 1, "Snapshot number should default to 1")
         }
         */
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

        /*
         @Test("Set default snapshot number to 1")
         func setDefaultSnapshotNumber() async {
             SharedReference.shared.rsyncversion3 = true

             let task = makeValidTask(
                 task: "snapshot",
                 username: "testuser",
                 server: "localhost"
             )
             let verifier = VerifyConfiguration()

             let result = verifier.verify(task)

             #expect(result?.snapshotnum == 1, "Should default snapshotnum to 1")
         }

         @Test("Preserve custom snapshot number")
         func preserveCustomSnapshotNumber() async {
             SharedReference.shared.rsyncversion3 = true

             // Using the extended AppendTask initializer
             let task = AppendTask(
                 "snapshot",
                 "/Users/test/Documents",
                 "/backup/Documents",
                 .add,
                 "testuser",
                 "localhost",
                 "TestBackup",
                 -1,
                 5
             )
             let verifier = VerifyConfiguration()

             let result = verifier.verify(task)

             #expect(result?.snapshotnum == 5, "Should preserve provided snapshotnum")
         }
         */
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
}

/* swiftlint:enable all */
