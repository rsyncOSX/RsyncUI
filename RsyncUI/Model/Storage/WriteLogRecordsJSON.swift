//
//  WriteLogRecordsJSON.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 27/04/2021.
//

import Foundation
import OSLog

@MainActor
enum WriteLogRecordsJSON {
    static func write(_ profile: String?, _ logrecords: [LogRecords]?) async {
        guard let logrecords else { return }
        let path = Homepath()
        guard let fullpathmacserial = path.fullpathmacserial else { return }

        // Build URL on main actor (fast)
        let base = URL(fileURLWithPath: fullpathmacserial)
        let fileURL: URL = if let profile {
            base.appendingPathComponent(profile)
                .appendingPathComponent(SharedConstants().filenamelogrecordsjson)
        } else {
            base.appendingPathComponent(SharedConstants().filenamelogrecordsjson)
        }

        do {
            try await SharedJSONStorageWriter.shared.write(logrecords, to: fileURL)
        } catch {
            path.propagateError(error: error)
            Logger.process.errorMessageOnly(
                "WriteLogRecordsJSON: persist failed - \(error.localizedDescription)"
            )
        }
    }
}
