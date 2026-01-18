//
//  WriteExportConfigurationsJSON.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 22/07/2024.
//

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
                    Logger.process.debugMessageOnly(
                        "WriteExportConfigurationsJSON - writing export configurations to permanent storage at \(exportpath)"
                    )
                } catch let err {
                    Logger.process.errorMessageOnly(
                        """
                        WriteExportConfigurationsJSON - failed to write export configurations to \
                        permanent storage at \(exportpath): \(String(describing: err))
                        """
                    )
                    let error = err
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
        } catch let err {
            let error = err
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
