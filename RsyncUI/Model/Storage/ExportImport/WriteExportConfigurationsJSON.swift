//
//  WriteExportConfigurationsJSON.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 22/07/2024.
//

import Foundation
import OSLog

@MainActor
enum WriteExportConfigurationsJSON {
    static func write(_ path: String?, _ configurations: [SynchronizeConfiguration]?) async {
        guard let path, let configurations else { return }

        let exportconfigurationfileURL = URL(fileURLWithPath: path)

        do {
            try await SharedJSONStorageWriter.shared.write(configurations, to: exportconfigurationfileURL)
            Logger.process.debugMessageOnly(
                "WriteExportConfigurationsJSON - writing export configurations to permanent storage at \(path)"
            )
        } catch {
            Logger.process.errorMessageOnly(
                """
                WriteExportConfigurationsJSON - failed to write export configurations to \
                permanent storage at \(path): \(String(describing: error))
                """
            )
            SharedReference.shared.errorobject?.alert(error: error)
        }
    }
}
