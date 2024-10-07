//
//  WriteExportConfigurationsJSON.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 22/07/2024.
//
// swiftlint:disable line_length

import DecodeEncodeGeneric
import Foundation
import OSLog

@MainActor
final class WriteExportConfigurationsJSON: PropogateError {
    var exportpath: String?

    private func writeJSONToPersistentStore(jsonData: Data?) {
        if let exportpath {
            let exportconfigurationfileURL = URL(fileURLWithPath: exportpath)

            if let jsonData {
                do {
                    try jsonData.write(to: exportconfigurationfileURL)
                    Logger.process.info("WriteExportConfigurationsJSON - \(exportpath, privacy: .public): write export configurations to permanent storage")
                } catch let e {
                    let error = e
                    propogateerror(error: error)
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
    init(_ path: String?, _ configurations: [SynchronizeConfiguration]?) {
        exportpath = path
        if let configurations {
            encodeJSONData(configurations)
        }
    }
}

// swiftlint:enable line_length
