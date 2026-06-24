//
//  ItemizedOutputTests.swift
//  RsyncUITests
//

@testable import RsyncUI
import Testing

struct ItemizedOutputTests {
    @Test("Classifies rsync itemized output")
    func classifiesOutput() throws {
        let added = try #require(ItemizedOutputRecord(">f+++++++++ new-file.txt"))
        let directory = try #require(ItemizedOutputRecord("cd+++++++++ new-folder/"))
        let updated = try #require(ItemizedOutputRecord(">f.st...... changed.txt"))
        let metadata = try #require(ItemizedOutputRecord(".d..t...... folder/"))
        let deleted = try #require(ItemizedOutputRecord("*deleting removed.txt"))

        #expect(added.kind == .added)
        #expect(directory.kind == .added)
        #expect(updated.kind == .updated)
        #expect(metadata.kind == .metadata)
        #expect(deleted.kind == .deleted)
        #expect(deleted.path == "removed.txt")
    }

    @Test("Supports openrsync itemized output")
    func supportsOpenRsync() throws {
        let added = try #require(ItemizedOutputRecord(">f+++++++ file.txt"))
        let metadata = try #require(ItemizedOutputRecord(".d..t.... folder/"))

        #expect(added.kind == .added)
        #expect(metadata.kind == .metadata)
    }

    @Test("Adds itemize flag once before source and destination")
    func addsRuntimeFlag() {
        let arguments = ["-a", "--dry-run", "/source/", "/destination/"]
        let updated = RuntimeRsyncArguments.addingItemizedChanges(
            to: arguments,
            forDisplay: false
        )
        let unchanged = RuntimeRsyncArguments.addingItemizedChanges(
            to: updated,
            forDisplay: false
        )

        #expect(updated == ["-a", "--dry-run", "--itemize-changes", "/source/", "/destination/"])
        #expect(unchanged == updated)
    }

    @Test("Preserves display argument spacing")
    func preservesDisplaySpacing() {
        let arguments = ["-a", " ", "/source/", " ", "/destination/", " "]
        let updated = RuntimeRsyncArguments.addingItemizedChanges(
            to: arguments,
            forDisplay: true
        )

        #expect(updated.joined() == "-a --itemize-changes /source/ /destination/ ")
    }
}
