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
        if let unwrappedArgs = args {
            #expect(unwrappedArgs.contains("--dry-run") || unwrappedArgs.contains("-n"))
        }
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
