@testable import RsyncUI
import Testing

@MainActor
struct RestoreSnapshotSelectionTests {
    @Test("Clearing a snapshot selection returns to latest without changing the saved task")
    func clearingSnapshot() throws {
        let restore = ObservableRestore()
        var config = SynchronizeConfiguration()
        config.task = "snapshot"
        config.snapshotnum = 10
        restore.selectedconfig = config
        restore.selectedSnapshot = "./3"
        #expect(try restore.configurationForRestore().snapshotnum == 4)
        #expect(restore.selectedconfig?.snapshotnum == 10)
        restore.restorefilelist = [RsyncOutputData(record: "./file")]
        restore.filestorestore = "./file"
        restore.selectedSnapshot = nil
        #expect(try restore.configurationForRestore().snapshotnum == 10)
        #expect(restore.restorefilelist.isEmpty)
        #expect(restore.filestorestore.isEmpty)
    }

    @Test("Changing tasks clears the selected snapshot and files")
    func changingTask() {
        let restore = ObservableRestore()
        restore.selectedconfig = SynchronizeConfiguration()
        restore.selectedSnapshot = "./3"
        restore.filestorestore = "./old-file"
        restore.restorefilelist = [RsyncOutputData(record: "./old-file")]
        restore.selectedconfig = SynchronizeConfiguration()
        #expect(restore.selectedSnapshot == nil)
        #expect(restore.filestorestore.isEmpty)
        #expect(restore.restorefilelist.isEmpty)
    }
}
