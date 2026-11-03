//
//  WriteSynchronizeConfigurationJSON.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 27/04/2021.
//

import Foundation
import OSLog

@MainActor
enum WriteSynchronizeConfigurationJSON {
    @discardableResult
    static func write(_ profile: String?, _ configurations: [SynchronizeConfiguration]?) async -> Bool {
        guard let configurations else { return false }
        let path = Homepath()
        guard let fullpathmacserial = path.fullpathmacserial else { return false }

        // Build URL on main actor (fast)
        let base = URL(fileURLWithPath: fullpathmacserial)
        let fileURL: URL = if let profile {
            base.appendingPathComponent(profile)
                .appendingPathComponent(SharedConstants().fileconfigurationsjson)
        } else {
            base.appendingPathComponent(SharedConstants().fileconfigurationsjson)
        }

        do {
            try await SharedJSONStorageWriter.shared.write(configurations, to: fileURL)
            return true
        } catch {
            path.propagateError(error: error)
            Logger.process.errorMessageOnly(
                "WriteSynchronizeConfigurationJSON: persist failed - \(error.localizedDescription)"
            )
            return false
        }
    }
}
