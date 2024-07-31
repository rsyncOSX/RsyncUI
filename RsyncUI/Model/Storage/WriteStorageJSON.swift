//
//  WriteStorageJSON.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 31/07/2024.
//

import Combine
import Foundation
import OSLog

@MainActor
struct WriteStorageJSON: PropogateError {
    private func writeJSONToPersistentStore(path: URL, jsonData: Data) {
        do {
            try jsonData.write(to: path)
            Logger.process.info("WriteStorageJSON - \(path, privacy: .public): write data to permanent storage")
        } catch let e {
            let error = e
            propogateerror(error: error)
        }
    }

    @discardableResult
    init(_ stringPath: String?, _ jsonData: Data?) {
        if let stringPath = stringPath, let jsonData = jsonData {
            let URLPath = URL(fileURLWithPath: stringPath)
            writeJSONToPersistentStore(path: URLPath, jsonData: jsonData)
        }
    }
}
