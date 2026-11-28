//
//  SnapshotSSHPortTests.swift
//  RsyncUITests
//

@testable import RsyncUI
import Testing

@MainActor
@Suite("SSH port for the remote snapshot check", .tags(.validation))
struct SnapshotSSHPortTests {
    private func config(port: Int?) -> SynchronizeConfiguration {
        var config = SynchronizeConfiguration()
        config.offsiteServer = "nas.local"
        config.sshport = port
        return config
    }

    @Test("The task's own port is used first")
    func taskPort() {
        #expect(VerifyConfiguration.sshPort(for: config(port: 2222), globalPort: 2200) == 2222)
    }

    @Test("The global port is used when the task has none")
    func globalPort() {
        #expect(VerifyConfiguration.sshPort(for: config(port: nil), globalPort: 2200) == 2200)
        #expect(VerifyConfiguration.sshPort(for: config(port: -1), globalPort: 2200) == 2200)
    }

    @Test("Port 22 when neither is set")
    func defaultPort() {
        #expect(VerifyConfiguration.sshPort(for: config(port: nil), globalPort: nil) == 22)
        #expect(VerifyConfiguration.sshPort(for: config(port: -1), globalPort: -1) == 22)
    }
}
