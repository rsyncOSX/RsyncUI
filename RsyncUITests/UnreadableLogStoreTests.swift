//
//  UnreadableLogStoreTests.swift
//  RsyncUITests
//

import Foundation
@testable import RsyncUI
import Testing

@Suite("Unreadable log records file", .tags(.logs, .storage))
struct UnreadableLogStoreTests {
    private func makeDirectory() throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("UnreadableLogStoreTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    @Test("A missing file reads as nil, not as an error")
    func missingFile() async throws {
        let directory = try makeDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let result = try await LogStoreService.readStore(at: directory.appendingPathComponent("logrecords.json"),
                                                         validHiddenIDs: [1])
        #expect(result == nil)
    }

    @Test("One malformed record makes the read throw instead of returning an empty store")
    func malformedFileThrows() async throws {
        let directory = try makeDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let fileURL = directory.appendingPathComponent("logrecords.json")
        let json = #"[{"hiddenID":1,"dateStart":"x","logrecords":[]},{"hiddenID":"not a number"}]"#
        try Data(json.utf8).write(to: fileURL)
        await #expect(throws: (any Error).self) {
            _ = try await LogStoreService.readStore(at: fileURL, validHiddenIDs: [1])
        }
    }

    @Test("A valid file keeps only records for known tasks")
    func validFileFilters() async throws {
        let directory = try makeDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let fileURL = directory.appendingPathComponent("logrecords.json")
        let json = #"[{"hiddenID":1,"dateStart":"a"},{"hiddenID":2,"dateStart":"b"}]"#
        try Data(json.utf8).write(to: fileURL)
        let result = try await LogStoreService.readStore(at: fileURL, validHiddenIDs: [2])
        #expect(result?.map(\.hiddenID) == [2])
    }

    @Test("An unreadable file is moved aside with its contents intact")
    func setAsideKeepsContents() throws {
        let directory = try makeDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let fileURL = directory.appendingPathComponent("logrecords.json")
        let contents = Data("[{\"broken\"".utf8)
        try contents.write(to: fileURL)

        let now = try #require(ISO8601DateFormatter().date(from: "2026-11-27T08:15:30Z"))
        let backup = try LogStoreService.setAsideUnreadableStore(at: fileURL, now: now)

        #expect(FileManager.default.fileExists(atPath: fileURL.path) == false)
        #expect(backup.lastPathComponent.hasPrefix("logrecords.json.unreadable-20261127-"))
        #expect(try Data(contentsOf: backup) == contents)
    }
}
