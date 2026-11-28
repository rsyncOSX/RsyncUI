//
//  CommandDisplayTests.swift
//  RsyncUITests
//

@testable import RsyncUI
import Testing

@MainActor
@Suite("Displayed commands", .serialized, .tags(.arguments))
struct CommandDisplayTests {
    private func makeConfiguration() -> SynchronizeConfiguration {
        var configuration = SynchronizeConfiguration()
        configuration.task = SharedReference.shared.synchronize
        configuration.localCatalog = "/Users/test/My Documents/"
        configuration.offsiteCatalog = "/backup/Documents"
        configuration.offsiteUsername = "test"
        configuration.offsiteServer = "server"
        configuration.sshport = 22
        configuration.sshkeypathandidentityfile = "~/.ssh/id_rsa"
        return configuration
    }

    @Test("Quote only what the shell would change")
    func quoting() {
        #expect(ShellCommand.quoted("--exclude=.DS_Store") == "--exclude=.DS_Store")
        #expect(ShellCommand.quoted("ssh -p 22") == "'ssh -p 22'")
        #expect(ShellCommand.quoted("--exclude=*.o") == "'--exclude=*.o'")
        #expect(ShellCommand.quoted("it's") == "'it'\\''s'")
        #expect(ShellCommand.quoted("~/backup") == "'~/backup'")
        #expect(ShellCommand.quoted("") == "''")
    }

    @Test("Synchronize shows the command which is executed")
    func synchronizeCommand() throws {
        let configuration = makeConfiguration()
        let command = RsyncCommandtoDisplay(display: .synchronizeData, config: configuration).rsynccommand
        let arguments = try #require(ArgumentsSynchronize(config: configuration)
            .argumentsSynchronize(dryRun: false, forDisplay: false))

        #expect(command == ShellCommand.line(GetfullpathforRsync().rsyncpath(), arguments))
        #expect(command.contains("--dry-run") == false)
        #expect(command.contains("'/Users/test/My Documents/'"))
        #expect(command.contains("''") == false)
    }

    @Test("Verify is still a dry run")
    func verifyCommand() {
        let command = RsyncCommandtoDisplay(display: .verifySynchronizedData, config: makeConfiguration()).rsynccommand
        #expect(command.contains("--dry-run"))
    }

    @Test("List remote files quotes the ssh command")
    func listRemoteFilesCommand() {
        let command = OtherRsyncCommandtoDisplay(display: .listRemoteFiles, config: makeConfiguration()).command
        #expect(command.contains("-e 'ssh -i ~/.ssh/id_rsa -p 22' test@server:/backup/Documents"))
    }
}
