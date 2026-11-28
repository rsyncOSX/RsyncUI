//
//  GlobalSSHSettingsTests.swift
//  RsyncUITests
//

import Foundation
@testable import RsyncUI
import Testing

@MainActor
@Suite("Global SSH port and key reach rsync", .serialized, .tags(.arguments))
struct GlobalSSHSettingsTests {
    private func remoteConfig(port: Int? = nil, key: String? = nil) -> SynchronizeConfiguration {
        var config = SynchronizeConfiguration()
        config.task = "synchronize"
        config.localCatalog = "/Users/test/Documents/"
        config.offsiteCatalog = "/backup/Documents/"
        config.offsiteUsername = "user"
        config.offsiteServer = "nas.local"
        config.halted = 0
        config.sshport = port
        config.sshkeypathandidentityfile = key
        return config
    }

    /// The value after "-e", or nil when rsync gets no SSH command.
    private func sshCommand(_ config: SynchronizeConfiguration,
                            globalPort: Int?,
                            globalKey: String?) throws -> String? {
        let savedPort = SharedReference.shared.sshport
        let savedKey = SharedReference.shared.sshkeypathandidentityfile
        SharedReference.shared.sshport = globalPort
        SharedReference.shared.sshkeypathandidentityfile = globalKey
        defer {
            SharedReference.shared.sshport = savedPort
            SharedReference.shared.sshkeypathandidentityfile = savedKey
        }
        let args = try #require(ArgumentsSynchronize(config: config).argumentsSynchronize(dryRun: true, forDisplay: false))
        guard let index = args.firstIndex(of: "-e"), args.indices.contains(index + 1) else { return nil }
        return args[index + 1]
    }

    @Test("The global port is used when the task has none")
    func globalPortOnly() throws {
        #expect(try sshCommand(remoteConfig(), globalPort: 2222, globalKey: nil) == "ssh -p 2222")
        #expect(try sshCommand(remoteConfig(port: -1), globalPort: 2222, globalKey: nil) == "ssh -p 2222")
    }

    @Test("The global key is used when the task has none")
    func globalKeyOnly() throws {
        #expect(try sshCommand(remoteConfig(), globalPort: nil, globalKey: "~/.ssh_rsyncosx/rsyncosx")
            == "ssh -i ~/.ssh_rsyncosx/rsyncosx")
    }

    @Test("The task's own port and key override the global ones")
    func taskOverridesGlobal() throws {
        let config = remoteConfig(port: 2200, key: "~/.ssh/task_key")
        #expect(try sshCommand(config, globalPort: 2222, globalKey: "~/.ssh/global_key")
            == "ssh -i ~/.ssh/task_key -p 2200")
    }

    @Test("No SSH command when nothing is set")
    func nothingSet() throws {
        #expect(try sshCommand(remoteConfig(), globalPort: nil, globalKey: nil) == nil)
        #expect(try sshCommand(remoteConfig(port: -1, key: ""), globalPort: -1, globalKey: "") == nil)
    }

    @Test("A daemon task never gets the global SSH port or key")
    func daemonIgnoresGlobal() throws {
        var config = remoteConfig()
        config.rsyncdaemon = 1
        #expect(try sshCommand(config, globalPort: 2222, globalKey: "~/.ssh_rsyncosx/rsyncosx") == nil)
    }

    @Test("A daemon task keeps its own SSH settings, as before")
    func daemonKeepsOwnSettings() throws {
        var config = remoteConfig(port: 2200)
        config.rsyncdaemon = 1
        #expect(try sshCommand(config, globalPort: 2222, globalKey: "~/.ssh/global_key") == "ssh -p 2200")
    }

    @Test("Values that are not set become nil, not empty strings")
    func notSetIsNil() {
        #expect(SSHParams.portString(nil) == nil)
        #expect(SSHParams.portString(-1) == nil)
        #expect(SSHParams.portString(2222) == "2222")
        #expect(SSHParams.keyString(nil) == nil)
        #expect(SSHParams.keyString("") == nil)
        #expect(SSHParams.keyString("~/.ssh/key") == "~/.ssh/key")
    }
}
