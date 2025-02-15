//
//  VerifyDuplicates.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 24/10/2024.
//

import Foundation
import OSLog

@MainActor
struct VerifyDuplicates {
    private var arrayofhiddenIDs = [Int]()

    private func checkforduplicates() throws {
        let uniqueIDs = Set(arrayofhiddenIDs)
        guard arrayofhiddenIDs.count == uniqueIDs.count else {
            throw DuplicateError.duplicate
        }
    }

    @discardableResult
    init(_ configurations: [SynchronizeConfiguration]) {
        _ = configurations.map { record in
            arrayofhiddenIDs.append(record.hiddenID)
        }
        Logger.process.info("VerifyDuplicates: doing a check for duplicates")
        do {
            try checkforduplicates()
        } catch let e {
            let error = e
            propogateerror(error: error)
        }
    }

    func propogateerror(error: Error) {
        SharedReference.shared.errorobject?.alert(error: error)
    }
}

enum DuplicateError: LocalizedError {
    case duplicate

    var errorDescription: String? {
        switch self {
        case .duplicate:
            "Oh my, you've got a duplicate hiddenID!"
        }
    }
}

// swiftlint:enable line_length
