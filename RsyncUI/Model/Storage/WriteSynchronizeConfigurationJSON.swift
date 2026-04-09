//
//  WriteSynchronizeConfigurationJSON.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 27/04/2021.
//

import DecodeEncodeGeneric
import Foundation
import OSLog

@MainActor
final class WriteSynchronizeConfigurationJSON {
    @discardableResult
    init(_ profile: String?, _ configurations: [SynchronizeConfiguration]?) {
        guard let configurations else { return }
        let path = Homepath()
        guard let fullpathmacserial = path.fullpathmacserial else { return }

        // Build URL on main actor (fast)
        let base = URL(fileURLWithPath: fullpathmacserial)
        let fileURL: URL
        if let profile {
            fileURL = base.appendingPathComponent(profile)
                .appendingPathComponent(SharedConstants().fileconfigurationsjson)
        } else {
            fileURL = base.appendingPathComponent(SharedConstants().fileconfigurationsjson)
        }

        // Encode on main actor (CPU-bound, fast)
        let encodeddata: Data
        do {
            encodeddata = try EncodeGeneric().encode(configurations)
        } catch let err {
            path.propagateError(error: err)
            return
        }

        // Write off the main thread
        Logger.process.debugMessageOnly("WriteSynchronizeConfigurationJSON: writing to \(fileURL)")
        Task.detached(priority: .utility) {
            do {
                try encodeddata.write(to: fileURL)
            } catch {
                await MainActor.run {
                    SharedReference.shared.errorobject?.alert(error: error)
                }
                Logger.process.errorMessageOnly(
                    "WriteSynchronizeConfigurationJSON: write failed - \(error.localizedDescription)"
                )
            }
        }
    }

    deinit {
        Logger.process.debugMessageOnly("WriteSynchronizeConfigurationJSON DEINIT")
    }
}
