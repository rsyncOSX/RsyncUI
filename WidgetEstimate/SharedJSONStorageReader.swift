//
//  SharedJSONStorageReader.swift
//  WidgetEstimate
//

import Foundation
import OSLog

actor SharedJSONStorageReader {
    static let shared = SharedJSONStorageReader()
    private static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "WidgetEstimate",
        category: "process"
    )

    private init() {}

    func decode<T: Decodable & Sendable>(_ type: T.Type, from fileURL: URL) async throws -> T {
        Self.logger.debug("SharedJSONStorageReader: reading from \(fileURL.path, privacy: .public)")
        return try await Task.detached(priority: .utility) {
            let data = try Data(contentsOf: fileURL)
            return try JSONDecoder().decode(type, from: data)
        }.value
    }
}
