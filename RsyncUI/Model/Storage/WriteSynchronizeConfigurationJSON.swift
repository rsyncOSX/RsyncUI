//
//  WriteSynchronizeConfigurationJSON.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 27/04/2021.
//
// swiftlint:disable line_length

import DecodeEncodeGeneric
import Foundation
import OSLog

@MainActor
final class WriteSynchronizeConfigurationJSON: PropogateError {
    var profile: String?

    private func writeJSONToPersistentStore(jsonData: Data?) {
        let path = Homepath()
        if let fullpathmacserial = path.fullpathmacserial {
            var configurationfileURL: URL?
            let fullpathmacserialURL = URL(fileURLWithPath: fullpathmacserial)
            if let profile {
                let tempURL = fullpathmacserialURL.appendingPathComponent(profile)
                configurationfileURL = tempURL.appendingPathComponent(SharedReference.shared.fileconfigurationsjson)

            } else {
                configurationfileURL = fullpathmacserialURL.appendingPathComponent(SharedReference.shared.fileconfigurationsjson)
            }
            if let jsonData, let configurationfileURL {
                do {
                    try jsonData.write(to: configurationfileURL)
                    let myprofile = profile
                    Logger.process.info("WriteSynchronizeConfigurationJSON - \(myprofile ?? "default profile", privacy: .public): write configurations to permanent storage")
                } catch let e {
                    let error = e
                    path.propogateerror(error: error)
                }
            }
        }
    }

    private func encodeJSONData(_ configurations: [SynchronizeConfiguration]) {
        let encodejsondata = EncodeGeneric()
        do {
            if let encodeddata = try encodejsondata.encodedata(data: configurations) {
                writeJSONToPersistentStore(jsonData: encodeddata)
            }
        } catch let e {
            let error = e
            propogateerror(error: error)
        }
    }

    @discardableResult
    init(_ profile: String?, _ configurations: [SynchronizeConfiguration]?) {
        if profile == SharedReference.shared.defaultprofile {
            self.profile = nil
        } else {
            self.profile = profile
        }
        if let configurations {
            encodeJSONData(configurations)
        }
    }

    deinit {
        Logger.process.info("WriteSynchronizeConfigurationJSON deinit")
    }
}

// swiftlint:enable line_length
