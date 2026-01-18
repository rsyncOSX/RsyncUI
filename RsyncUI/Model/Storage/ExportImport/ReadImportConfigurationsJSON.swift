//
//  ReadImportConfigurationsJSON.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 23/07/2024.
//

import DecodeEncodeGeneric
import Foundation
import OSLog

@MainActor
final class ReadImportConfigurationsJSON {
    var importconfigurations: [SynchronizeConfiguration]?
    var maxhiddenID: Int = -1

    private func importjsonfile(_ filenameimport: String) {
        let decodeimport = DecodeGeneric()
        do {
            let importeddata = try
                decodeimport.decodeArray(DecodeSynchronizeConfiguration.self, fromFile: filenameimport)

            importconfigurations = importeddata.map { importrecord in
                var element = SynchronizeConfiguration(importrecord)
                element.hiddenID = maxhiddenID + 1
                element.dateRun = nil
                element.backupID = "IMPORT: " + (importrecord.backupID ?? "")
                element.id = UUID()
                maxhiddenID += 1
                return element
            }
            let message = "ReadImportConfigurationsJSON - \(filenameimport) read import configurations from permanent storage"
            Logger.process.debugMessageOnly(message)
        } catch {
            let message = "ReadImportConfigurationsJSON - \(filenameimport): ERROR reading import configurations"
            Logger.process.errorMessageOnly(message)
            return
        }
    }

    init(_ filenameimport: String, maxhiddenId: Int) {
        maxhiddenID = maxhiddenId
        importjsonfile(filenameimport)
    }
}
