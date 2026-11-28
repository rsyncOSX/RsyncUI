//
//  ReadSynchronizeConfigurationJSON.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 19/04/2021.
//

import Foundation
import OSLog

@MainActor
struct ReadSynchronizeConfigurationJSON {
    func readjsonfilesynchronizeconfigurations(_ profile: String?,
                                               _ rsyncversion3: Bool) async -> [SynchronizeConfiguration]? {
        let path = Homepath()

        Logger.process.debugThreadOnly("ReadSynchronizeConfigurationJSON: readjsonfilesynchronizeconfigurations()")

        guard let fullpathmacserial = path.fullpathmacserial else { return nil }

        let baseURL = URL(fileURLWithPath: fullpathmacserial)
        let fileURL: URL = if let profile {
            baseURL.appendingPathComponent(profile)
                .appendingPathComponent(SharedConstants().fileconfigurationsjson)
        } else {
            baseURL.appendingPathComponent(SharedConstants().fileconfigurationsjson)
        }

        do {
            let data = try await SharedJSONStorageReader.shared.decodeArray(
                DecodeSynchronizeConfiguration.self,
                from: fileURL
            )

            Logger.process.debugThreadOnly("ReadSynchronizeConfigurationJSON - \(profile ?? "default") ?? DECODE")
            let configurations = data.map { SynchronizeConfiguration($0) }
            // Tasks requiring rsync 3.x are hidden, not dropped: they are written back on save.
            let hidden = configurations.filter {
                HiddenConfigurations.isHidden(task: $0.task, rsyncversion3: rsyncversion3)
            }
            HiddenConfigurations.set(hidden, profile: profile)
            return configurations.filter {
                !HiddenConfigurations.isHidden(task: $0.task, rsyncversion3: rsyncversion3)
            }
        } catch {
            let profileName = profile ?? "default profile"
            let errorMessage = "ReadSynchronizeConfigurationJSON - \(profileName): " +
                "some ERROR reading synchronize configurations from permanent storage"
            Logger.process.errorMessageOnly(errorMessage)
            return nil
        }
    }
}
