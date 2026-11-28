//
//  ObservableParametersRsyncTests.swift
//  RsyncUITests
//

@testable import RsyncUI
import Testing

@MainActor
@Suite("Backup arguments")
struct ObservableParametersRsyncTests {
    private func makeConfiguration() -> SynchronizeConfiguration {
        var configuration = SynchronizeConfiguration()
        configuration.localCatalog = "/Users/test/Documents/"
        configuration.offsiteCatalog = "/backup/Documents"
        return configuration
    }

    @Test("A saved backup task is shown as enabled")
    func savedBackupIsEnabled() {
        var configuration = makeConfiguration()
        configuration.parameter12 = "--backup"
        configuration.parameter13 = "--backup-dir=../backup_Documents"

        let parameters = ObservableParametersRsync()
        parameters.setvalues(configuration)
        #expect(parameters.backupIsEnabled)

        parameters.setbackup(true)
        #expect(parameters.parameter12 == "--backup")

        parameters.setbackup(false)
        #expect(parameters.backupIsEnabled == false)
        #expect(parameters.parameter12.isEmpty)
        #expect(parameters.parameter13.isEmpty)
    }

    @Test("Selecting another task does not change its arguments")
    func selectingAnotherTask() {
        let parameters = ObservableParametersRsync()
        parameters.setvalues(makeConfiguration())
        parameters.setbackup(true)
        #expect(parameters.parameter12 == "--backup")
        #expect(parameters.parameter13 == "--backup-dir=../backup_Documents")

        parameters.setvalues(makeConfiguration())
        #expect(parameters.backupIsEnabled == false)
        #expect(parameters.parameter12.isEmpty)
    }

    @Test("Other arguments are kept")
    func otherArgumentsAreKept() {
        var configuration = makeConfiguration()
        configuration.parameter12 = "--exclude=build"

        let parameters = ObservableParametersRsync()
        parameters.setvalues(configuration)
        parameters.setbackup(true)
        #expect(parameters.parameter12 == "--exclude=build")
        #expect(parameters.parameter13 == "--backup")
        #expect(parameters.parameter14 == "--backup-dir=../backup_Documents")

        parameters.setbackup(false)
        #expect(parameters.parameter12 == "--exclude=build")
        #expect(parameters.backupIsEnabled == false)
    }

    @Test("Backup is not half enabled without room for its arguments")
    func noFreeSlots() {
        var configuration = makeConfiguration()
        configuration.parameter8 = "--exclude=a"
        configuration.parameter9 = "--exclude=b"
        configuration.parameter10 = "--exclude=c"
        configuration.parameter11 = "--exclude=d"
        configuration.parameter12 = "--exclude=e"
        configuration.parameter13 = "--exclude=f"

        let parameters = ObservableParametersRsync()
        parameters.setvalues(configuration)
        parameters.setbackup(true)
        #expect(parameters.backupIsEnabled == false)
        #expect(parameters.parameter14.isEmpty)
    }

    @Test("Show only the arguments in use, and add one at a time")
    func visibleArguments() {
        var configuration = makeConfiguration()
        configuration.parameter8 = "--exclude=a"
        configuration.parameter10 = "--exclude=b"

        let parameters = ObservableParametersRsync()
        parameters.setvalues(configuration)
        #expect(parameters.visibleArgumentSlots == [0, 2])

        parameters.addArgument()
        #expect(parameters.visibleArgumentSlots == [0, 1, 2])

        // A cleared argument stays visible while it is edited
        parameters.setArgument("", in: 0)
        #expect(parameters.visibleArgumentSlots == [0, 1, 2])
        #expect(parameters.parameter8.isEmpty)

        for _ in 0 ..< 10 { parameters.addArgument() }
        #expect(parameters.visibleArgumentSlots == Array(0 ... 6))
        #expect(parameters.canAddArgument == false)

        parameters.setvalues(makeConfiguration())
        #expect(parameters.visibleArgumentSlots.isEmpty)
    }
}
