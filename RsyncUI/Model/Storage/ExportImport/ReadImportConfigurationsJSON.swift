//
//  ReadImportConfigurationsJSON.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 23/07/2024.
//

import Foundation
import OSLog

@MainActor
enum ReadImportConfigurationsJSON {
    static func read(_ filenameimport: String, maxhiddenId: Int) async -> [SynchronizeConfiguration]? {
        do {
            let fileURL = URL(fileURLWithPath: filenameimport)
            let importeddata = try await SharedJSONStorageReader.shared.decodeArray(
                DecodeSynchronizeConfiguration.self,
                from: fileURL
            )
            var nextHiddenID = maxhiddenId

            let importconfigurations = importeddata.map { importrecord in
                nextHiddenID += 1
                var element = SynchronizeConfiguration(importrecord)
                element.hiddenID = nextHiddenID
                element.dateRun = nil
                element.shortcutsapproval = nil
                element.backupID = "IMPORT: " + (importrecord.backupID ?? "")
                element.id = UUID()
                return element
            }
            let message = "ReadImportConfigurationsJSON - \(filenameimport) read import configurations from permanent storage"
            Logger.process.debugMessageOnly(message)
            return importconfigurations
        } catch {
            let message = "ReadImportConfigurationsJSON - \(filenameimport): ERROR reading import configurations"
            Logger.process.errorMessageOnly(message)
            return nil
        }
    }
}
