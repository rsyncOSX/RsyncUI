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
final class ReadImportConfigurationsJSON: PropogateError {
    var importconfigurations: [SynchronizeConfiguration]?
    var maxhiddenID: Int = -1

    private func importjsonfile(_ filenameimport: String) {
        let decodeimport = DecodeGeneric()
        do {
            if let importeddata = try
                decodeimport.decodearraydatafileURL(DecodeSynchronizeConfiguration.self, fromwhere: filenameimport)
            {
                var importconfigurations = [SynchronizeConfiguration]()
                for i in 0 ..< importeddata.count {
                    var element = SynchronizeConfiguration(importeddata[i])
                    element.hiddenID = maxhiddenID + 1 + i
                    element.dateRun = nil
                    element.backupID = "IMPORT: " + (importeddata[i].backupID ?? "")
                    element.id = UUID()
                    importconfigurations.append(element)
                }
                self.importconfigurations = importconfigurations

                Logger.process.info("ReadImportConfigurationsJSON - \(filenameimport, privacy: .public): read import configurations from permanent storage")
            }

        } catch let e {
            let error = e
            propogateerror(error: error)
        }
    }

    init(_ filenameimport: String, maxhiddenId: Int) {
        maxhiddenID = maxhiddenId
        importjsonfile(filenameimport)
    }
}

// swiftlint:enable line_length
