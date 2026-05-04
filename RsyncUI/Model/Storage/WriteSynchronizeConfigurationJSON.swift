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
    static func write(_ profile: String?, _ configurations: [SynchronizeConfiguration]?) async {
        guard let configurations else { return }
        let path = Homepath()
        guard let fullpathmacserial = path.fullpathmacserial else { return }

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
        } catch {
            path.propagateError(error: error)
            Logger.process.errorMessageOnly(
                "WriteSynchronizeConfigurationJSON: persist failed - \(error.localizedDescription)"
            )
        }
    }
}
