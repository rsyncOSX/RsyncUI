//
//  SharedJSONStorageWriter.swift
//  RsyncUI
//

import Foundation
import OSLog

actor SharedJSONStorageWriter {
    static let shared = SharedJSONStorageWriter()

    private init() {}

    func write(_ data: Data, to fileURL: URL) throws {
        Logger.process.debugMessageOnly("SharedJSONStorageWriter: writing to \(fileURL)")
        try data.write(to: fileURL)
    }
}
