@testable import RsyncUI
import Testing

@MainActor
struct RestoreSearchTests {
    @Test("Broadening and clearing a restore search recovers original files and identities")
    func reversibleSearch() {
        let restore = ObservableRestore()
        restore.restorefilelist = [RsyncOutputData(record: "./report.txt"), RsyncOutputData(record: "./receipt.txt")]
        let originalIDs = restore.restorefilelist.map(\.id)
        #expect(restore.files(matching: "report").count == 1)
        #expect(restore.files(matching: "re").count == 2)
        #expect(restore.files(matching: "missing").isEmpty)
        #expect(restore.files(matching: "").map(\.id) == originalIDs)
        #expect(restore.restorefilelist.count == 2)
    }
}
