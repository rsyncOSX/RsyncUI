//
//  SharedJSONStorageTests.swift
//  RsyncUITests
//

import Foundation
import os
@testable import RsyncUI
import Testing

@Suite(.tags(.storage))
struct SharedJSONStorageTests {
    @Test("Shared JSON storage round-trips a single value")
    func roundTripSingleValue() async throws {
        let directoryURL = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directoryURL) }

        let fileURL = directoryURL.appendingPathComponent("single.json")
        let sample = SampleRecord(id: 7, name: "single")

        try await SharedJSONStorageWriter.shared.write(sample, to: fileURL)

        let decoded = try await SharedJSONStorageReader.shared.decode(SampleRecord.self, from: fileURL)

        #expect(decoded == sample)
    }

    @Test("Shared JSON storage round-trips arrays")
    func roundTripArray() async throws {
        let directoryURL = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directoryURL) }

        let fileURL = directoryURL.appendingPathComponent("array.json")
        let sample = [
            SampleRecord(id: 1, name: "first"),
            SampleRecord(id: 2, name: "second")
        ]

        try await SharedJSONStorageWriter.shared.write(sample, to: fileURL)

        let decoded = try await SharedJSONStorageReader.shared.decodeArray(SampleRecord.self, from: fileURL)

        #expect(decoded == sample)
    }

    @Test("Overlapping saves commit the last accepted value as complete JSON")
    func overlappingSaves() async throws {
        let directoryURL = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directoryURL) }
        let fileURL = directoryURL.appendingPathComponent("overlapping.json")

        for _ in 0 ..< 10 {
            let accepted = OSAllocatedUnfairLock(initialState: [Int]())
            try await withThrowingTaskGroup(of: Void.self) { group in
                for id in 0 ..< 20 {
                    let value = TrackedSave(id: id, accepted: accepted)
                    group.addTask {
                        try await SharedJSONStorageWriter.shared.write(value, to: fileURL)
                        // A reader must see a complete committed value, even while
                        // other saves are pending. It may see a newer value.
                        let data = try Data(contentsOf: fileURL)
                        let saved = try JSONDecoder().decode([Int].self, from: data)
                        let first = try #require(saved.first)
                        #expect(saved.allSatisfy { $0 == first })
                    }
                }
                try await group.waitForAll()
            }
            // Task submission order is not actor acceptance order. Record acceptance
            // during encoding instead of relying on task scheduling or sleeps.
            let lastAccepted = try #require(accepted.withLock { $0.last })
            let saved = try JSONDecoder().decode([Int].self, from: Data(contentsOf: fileURL))
            #expect(saved == TrackedSave.payload(for: lastAccepted))
        }
    }

    @Test("An encoding failure preserves the previous saved value")
    func failedEncodingPreservesExistingFile() async throws {
        let directoryURL = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directoryURL) }
        let fileURL = directoryURL.appendingPathComponent("existing.json")
        let original = SampleRecord(id: 1, name: "keep this")
        try await SharedJSONStorageWriter.shared.write(original, to: fileURL)
        let originalData = try Data(contentsOf: fileURL)

        await #expect(throws: (any Error).self) {
            try await SharedJSONStorageWriter.shared.write(Double.nan, to: fileURL)
        }

        #expect(try Data(contentsOf: fileURL) == originalData)
        // A rejected save must not prevent subsequent saves from completing.
        let replacement = SampleRecord(id: 2, name: "next save")
        try await SharedJSONStorageWriter.shared.write(replacement, to: fileURL)
        let decoded = try await SharedJSONStorageReader.shared.decode(SampleRecord.self, from: fileURL)
        #expect(decoded == replacement)
    }

    private func makeTemporaryDirectory() throws -> URL {
        let directoryURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(
            at: directoryURL,
            withIntermediateDirectories: true,
            attributes: nil
        )
        return directoryURL
    }
}

private struct TrackedSave: Encodable, Sendable {
    let id: Int
    let accepted: OSAllocatedUnfairLock<[Int]>

    static func payload(for id: Int) -> [Int] {
        Array(repeating: id, count: id.isMultiple(of: 2) ? 500_000 : 10)
    }

    func encode(to encoder: any Encoder) throws {
        accepted.withLock { $0.append(id) }
        var container = encoder.singleValueContainer()
        try container.encode(Self.payload(for: id))
    }
}

private struct SampleRecord: Codable, Equatable {
    let id: Int
    let name: String
}
