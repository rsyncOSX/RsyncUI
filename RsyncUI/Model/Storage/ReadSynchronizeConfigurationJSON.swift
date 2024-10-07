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
                /*
                var configurations = [SynchronizeConfiguration]()
                for i in 0 ..< data.count {
                    var configuration = SynchronizeConfiguration(data[i])
                    configuration.profile = profile
                    configurations.append(configuration)
                }
                self.configurations = configurations
                */
                
                self.configurations = data.map({ element in
                    SynchronizeConfiguration(element)
                })
                
                Logger.process.info("ReadSynchronizeConfigurationJSON - \(profile ?? "default profile", privacy: .public): read configurations from permanent storage")
            } else {
                createdefaultfilelogrecords(profile)
            }

        } catch let e {
            let error = e
            propogateerror(error: error)
        }
    }

    private func createdefaultfilelogrecords(_ profile: String?) {
        var defaultlogrecords = [LogRecords()]
        guard defaultlogrecords.count == 1 else { return }
        // No file, write new file with default values
        Logger.process.info("ReadConfigurationJSON: \(profile ?? "default profile", privacy: .public), Creating default file for LogRecords")
        defaultlogrecords[0].dateStart = Date().en_us_string_from_date()
        WriteLogRecordsJSON(profile, defaultlogrecords)
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
}

// swiftlint:enable line_length
