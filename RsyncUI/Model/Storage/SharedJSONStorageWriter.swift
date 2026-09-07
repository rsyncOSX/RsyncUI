//
//  SharedJSONStorageWriter.swift
//  RsyncUI
//

import DecodeEncodeGeneric
import Foundation
import OSLog

actor SharedJSONStorageWriter {
    static let shared = SharedJSONStorageWriter()

    private init() {}

    func write(_ value: sending some Encodable & Sendable, to fileURL: URL) async throws {
        Logger.process.debugMessageOnly("SharedJSONStorageWriter: writing to \(fileURL)")
        let encodeddata = try EncodeGeneric().encode(value)
        // Do not suspend between accepting a save and committing it: another call
        // could otherwise overwrite a newer save while this actor is reentrant.
        // File I/O stays on this storage actor, away from the main actor.
        try encodeddata.write(to: fileURL, options: .atomic)
    }
}
