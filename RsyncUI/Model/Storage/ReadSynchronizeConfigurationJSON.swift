//
//  ReadSynchronizeConfigurationJSON.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 19/04/2021.
//
// swiftlint:disable line_length

import DecodeEncodeGeneric
import Foundation
import OSLog

@MainActor
final class ReadSynchronizeConfigurationJSON: PropogateError {
    var configurations: [SynchronizeConfiguration]?
    let path = Homepath()

    private func importjsonfile(_ filenamedatastore: String, profile: String?) {
        let decodeimport = DecodeGeneric()
        do {
            if let data = try
                decodeimport.decodearraydatafileURL(DecodeSynchronizeConfiguration.self, fromwhere: filenamedatastore)
            {
                configurations = data.map { element in
                    SynchronizeConfiguration(element)
                }

                Logger.process.info("ReadSynchronizeConfigurationJSON - \(profile ?? "default profile", privacy: .public): read configurations from permanent storage")
            }

        } catch let e {
            let error = e
            propogateerror(error: error)
        }
    }

    init(_ profile: String?) {
        var filename = ""
        if let profile, let path = path.fullpathmacserial {
            filename = path + "/" + profile + "/" + SharedReference.shared.fileconfigurationsjson
        } else {
            if let path = path.fullpathmacserial {
                filename = path + "/" + SharedReference.shared.fileconfigurationsjson
            }
        }
        importjsonfile(filename, profile: profile)
    }

    deinit {
        Logger.process.info("ReadSynchronizeConfigurationJSON: deinit")
    }
}

// swiftlint:enable line_length
