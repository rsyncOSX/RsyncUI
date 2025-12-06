//
//  ActorReadSynchronizeConfigurationJSON.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 19/04/2021.
//

import DecodeEncodeGeneric
import Foundation
import OSLog

actor ActorReadSynchronizeConfigurationJSON {
    @concurrent
    nonisolated func readjsonfilesynchronizeconfigurations(_ profile: String?,
                                                           _ rsyncversion3: Bool) async -> [SynchronizeConfiguration]? {
        var filename = ""
        let path = await Homepath()
        Logger.process.debugThreadOnly("ActorReadSynchronizeConfigurationJSON: readjsonfilesynchronizeconfigurations()")
        if let profile, let fullpathmacserial = path.fullpathmacserial {
            filename = fullpathmacserial.appending("/") + profile.appending("/") + SharedConstants().fileconfigurationsjson
        } else {
            if let fullpathmacserial = path.fullpathmacserial {
                filename = fullpathmacserial.appending("/") + SharedConstants().fileconfigurationsjson
            }
        }
        Logger.process.debugMessageOnly("ActorReadSynchronizeConfigurationJSON: readjsonfilesynchronizeconfigurations \(filename)")
        let decodeimport = DecodeGeneric()
        do {
            let data = try
                decodeimport.decodeArray(DecodeSynchronizeConfiguration.self, fromFile: filename)

            Logger.process.debugThreadOnly("ActorReadSynchronizeConfigurationJSON - \(profile ?? "default") ?? DECODE")
            let tasks = data.compactMap { element in
                // snapshot and syncremote tasks requiere version3.x of rsync
                if element.task == "snapshot" || element.task == "syncremote" {
                    if rsyncversion3 {
                        return SynchronizeConfiguration(element)
                    }
                } else {
                    return SynchronizeConfiguration(element)
                }
                return nil
            }

            return tasks

        } catch {
            Logger.process.error("ActorReadSynchronizeConfigurationJSON - \(profile ?? "default profile", privacy: .public): some ERROR reading synchronize configurations from permanent storage")
        }
        return nil
    }

    deinit {
        Logger.process.debugMessageOnly("ActorReadSynchronizeConfigurationJSON: DEINIT")
    }
}

@MainActor
struct ReportError {
    func propagateError(error: Error) {
        SharedReference.shared.errorobject?.alert(error: error)
    }
}
