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
final class WriteExportConfigurationsJSON {
    var exportpath: String?

    private func writeJSONToPersistentStore(jsonData: Data?) {
        if let exportpath {
            let exportconfigurationfileURL = URL(fileURLWithPath: exportpath)

            if let jsonData {
                do {
                    try jsonData.write(to: exportconfigurationfileURL)
                    Logger.process.debugmessageonly("WriteExportConfigurationsJSON - \(exportpath) write export configurations to permanent storage")
                } catch let e {
                    Logger.process.error("WriteExportConfigurationsJSON - \(exportpath) some ERROR write export configurations to permanent storage")
                    let error = e
                    propagateError(error: error)
                }
            }
        }
    }

    private func encodeJSONData(_ configurations: [SynchronizeConfiguration]) {
        let encodejsondata = EncodeGeneric()
        do {
            let encodeddata = try encodejsondata.encode(configurations)
            writeJSONToPersistentStore(jsonData: encodeddata)

        } catch let e {
            let error = e
            propagateError(error: error)
        }
    }

    func propagateError(error: Error) {
        SharedReference.shared.errorobject?.alert(error: error)
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
