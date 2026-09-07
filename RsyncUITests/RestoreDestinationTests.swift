import Foundation
@testable import RsyncUI
import Testing

@MainActor
struct RestoreDestinationTests {
    @Test("The visible destination overrides the previous shared destination")
    func currentDestination() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let previous = SharedReference.shared.pathforrestore
        defer { SharedReference.shared.pathforrestore = previous }
        SharedReference.shared.pathforrestore = "/previous/destination/"
        let restore = ObservableRestore()
        var config = SynchronizeConfiguration()
        config.task = "synchronize"
        config.offsiteCatalog = "/backup/"
        config.offsiteServer = "example.invalid"
        config.offsiteUsername = "backup"
        restore.selectedconfig = config
        restore.filestorestore = "./."
        restore.pathforrestore = directory.path
        let arguments = try restore.restoreArguments(forDisplay: false)
        #expect(arguments.last == directory.path + "/")
        for invalid in ["", directory.appendingPathComponent("missing").path] {
            restore.pathforrestore = invalid
            #expect(!restore.canRestore)
            #expect(throws: RestoreError.self) { try restore.restoreArguments(forDisplay: false) }
        }
    }

    @Test("A regular file cannot be a restore destination")
    func rejectsRegularFile() throws {
        let file = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try Data().write(to: file)
        defer { try? FileManager.default.removeItem(at: file) }
        #expect(throws: RestoreError.self) { try ObservableRestore.validatedDestination(file.path) }
    }
}
