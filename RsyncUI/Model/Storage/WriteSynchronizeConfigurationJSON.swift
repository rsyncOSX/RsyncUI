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
    let path = Homepath()

    private func writeJSONToPersistentStore(jsonData: Data?, _ profile: String?) {
        if let fullpathmacserial = path.fullpathmacserial {
            var configurationfileURL: URL?
            let fullpathmacserialURL = URL(fileURLWithPath: fullpathmacserial)
            if let profile {
                let tempURL = fullpathmacserialURL.appendingPathComponent(profile)
                configurationfileURL = tempURL.appendingPathComponent(SharedConstants().fileconfigurationsjson)

            } else {
                configurationfileURL = fullpathmacserialURL.appendingPathComponent(SharedConstants().fileconfigurationsjson)
            }
            if let configurationfileURL {
                Logger.process.debugMessageOnly(
                    "WriteSynchronizeConfigurationJSON: writeJSONToPersistentStore \(configurationfileURL)"
                )
            }
            if let jsonData, let configurationfileURL {
                do {
                    try jsonData.write(to: configurationfileURL)
                } catch let err {
                    let error = err
                    path.propagateError(error: error)
                }
            }
        }
    }

    private func encodeJSONData(_ configurations: [SynchronizeConfiguration], _ profile: String?) {
        let encodejsondata = EncodeGeneric()
        do {
            let encodeddata = try encodejsondata.encode(configurations)
            writeJSONToPersistentStore(jsonData: encodeddata, profile)

        } catch let err {
            let error = err
            path.propagateError(error: error)
        }
    }

    @discardableResult
    init(_ profile: String?, _ configurations: [SynchronizeConfiguration]?) {
        if let configurations {
            encodeJSONData(configurations, profile)
        }
    }

    deinit {
        Logger.process.debugMessageOnly("WriteSynchronizeConfigurationJSON DEINIT")
    }
}
