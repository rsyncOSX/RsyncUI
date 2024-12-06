//
//  ReadImportConfigurationsJSON.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 23/07/2024.
//
// swiftlint:disable line_length

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
            if let importeddata = try
                decodeimport.decodearraydatafileURL(DecodeSynchronizeConfiguration.self, fromwhere: filenameimport)
            {
                importconfigurations = importeddata.map { importrecord in
                    var element = SynchronizeConfiguration(importrecord)
                    element.hiddenID = maxhiddenID + 1
                    element.dateRun = nil
                    element.backupID = "IMPORT: " + (importrecord.backupID ?? "")
                    element.id = UUID()
                    maxhiddenID += 1
                    return element
                }
                Logger.process.info("ReadImportConfigurationsJSON - \(filenameimport, privacy: .public): read import configurations from permanent storage")
            }

        } catch {
            Logger.process.error("ReadImportConfigurationsJSON - \(filenameimport, privacy: .public): some ERROR read import configurations from permanent storage")
            return
        }
    }

    init(_ filenameimport: String, maxhiddenId: Int) {
        maxhiddenID = maxhiddenId
        importjsonfile(filenameimport)
    }
}

// swiftlint:enable line_length
