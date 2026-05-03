//
//  ReadSynchronizeConfigurationJSON.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 19/04/2021.
//

import DecodeEncodeGeneric
import Foundation
import OSLog

@MainActor
struct ReadSynchronizeConfigurationJSON {
    func readjsonfilesynchronizeconfigurations(_ profile: String?,
                                               _ rsyncversion3: Bool) -> [SynchronizeConfiguration]? {
        var filename = ""
        let path = Homepath()
        Logger.process.debugThreadOnly("ReadSynchronizeConfigurationJSON: readjsonfilesynchronizeconfigurations()")
        if let profile, let fullpathmacserial = path.fullpathmacserial {
            filename = fullpathmacserial.appending("/") + profile.appending("/") + SharedConstants().fileconfigurationsjson
        } else {
            if let fullpathmacserial = path.fullpathmacserial {
                filename = fullpathmacserial.appending("/") + SharedConstants().fileconfigurationsjson
            }
        }
        let decodeimport = DecodeGeneric()
        do {
            let data = try
                decodeimport.decodeArray(DecodeSynchronizeConfiguration.self, fromFile: filename)

            Logger.process.debugThreadOnly("ReadSynchronizeConfigurationJSON - \(profile ?? "default") ?? DECODE")
            return data.compactMap { element in
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
        } catch {
            let profileName = profile ?? "default profile"
            let errorMessage = "ActorReadSynchronizeConfigurationJSON - \(profileName): " +
                "some ERROR reading synchronize configurations from permanent storage"
            Logger.process.errorMessageOnly("\(errorMessage)")
        }
        return nil
    }
}
