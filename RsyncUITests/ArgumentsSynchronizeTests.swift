//
//  ArgumentsSynchronizeTests.swift
//  RsyncUITests
//
//  Created by Thomas Evensen on 18/12/2025.
//

import Foundation
import RsyncArguments
@testable import RsyncUI
import Testing

@MainActor
@Suite(.serialized, .tags(.arguments))
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
    func synchronizeDryRunArgs() throws {
        let originalVersion = SharedReference.shared.rsyncversion3
        SharedReference.shared.rsyncversion3 = true
        defer { SharedReference.shared.rsyncversion3 = originalVersion }

        let cfg = makeConfig()
        let originalParameter8 = cfg.parameter8
        let generator = ArgumentsSynchronize(config: cfg)
        let args = generator.argumentsSynchronize(dryRun: true, forDisplay: false)

        let unwrappedArgs = try #require(args)
        // Accept either common dry-run flags
        #expect(unwrappedArgs.contains("--dry-run") || unwrappedArgs.contains("-n"))
        #expect(unwrappedArgs.contains("--itemize-changes"))
        #expect(cfg.parameter8 == originalParameter8)
        #expect(unwrappedArgs.dropLast(2).contains("--itemize-changes"))
    }

    /**
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
    func syncremoteArgs() throws {
        let originalVersion = SharedReference.shared.rsyncversion3
        SharedReference.shared.rsyncversion3 = true
        defer { SharedReference.shared.rsyncversion3 = originalVersion }

        let cfg = makeConfig(task: SharedReference.shared.syncremote,
                             username: "testuser",
                             server: "testserver.local")
        let generator = ArgumentsSynchronize(config: cfg)
        let args = generator.argumentsSynchronize(dryRun: true, forDisplay: false)

        let unwrappedArgs = try #require(args)
        #expect(unwrappedArgs.contains("--itemize-changes"))
    }

    @Test("Push local→remote with keepdelete variations")
    func pushLocalToRemoteArgs() throws {
        let originalVersion = SharedReference.shared.rsyncversion3
        SharedReference.shared.rsyncversion3 = true
        defer { SharedReference.shared.rsyncversion3 = originalVersion }

        let cfg = makeConfig()
        let generator = ArgumentsSynchronize(config: cfg)

        let argsKeep = generator.argumentsforpushlocaltoremotewithparameters(dryRun: false,
                                                                             forDisplay: false,
                                                                             keepdelete: true)
        let argsNoKeep = generator.argumentsforpushlocaltoremotewithparameters(dryRun: false,
                                                                               forDisplay: false,
                                                                               keepdelete: false)

        let unwrappedArgsKeep = try #require(argsKeep)
        let unwrappedArgsNoKeep = try #require(argsNoKeep)
        #expect(unwrappedArgsKeep.filter { $0 == "--itemize-changes" }.count == 1)
        #expect(unwrappedArgsNoKeep.filter { $0 == "--itemize-changes" }.count == 1)
    }
}
