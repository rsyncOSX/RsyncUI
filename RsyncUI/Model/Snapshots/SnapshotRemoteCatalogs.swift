//
//  SnapshotRemoteCatalogs.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 19/09/2023.
//

import Foundation
import OSLog

@MainActor
class SnapshotRemoteCatalogs {
    var mysnapshotdata: SnapshotData?
    var catalogsanddates: [Catalogsanddates]?

    func getremotecataloginfo(_ config: SynchronizeConfiguration) {
        let arguments = ArgumentsSnapshotRemoteCatalogs(config: config).remotefilelistarguments()
        let command = ProcessRsync(arguments: arguments,
                                   processtermination: processtermination)
        command.executeProcess()
    }

    init(config: SynchronizeConfiguration,
         snapshotdata: SnapshotData)
    {
        guard config.task == SharedReference.shared.snapshot else { return }
        mysnapshotdata = snapshotdata
        getremotecataloginfo(config)
    }

    func processtermination(stringoutputfromrsync: [String]?, hiddenID _: Int?) {
        if let stringoutputfromrsync {
            var catalogs = TrimOutputForRestore(stringoutputfromrsync).trimmeddata

            if let index = catalogs.firstIndex(where: { $0 == "./done" }) {
                catalogs.remove(at: index)
            }
            if let index = catalogs.firstIndex(where: { $0 == "./." }) {
                catalogs.remove(at: index)
            }
            catalogsanddates = catalogs.map { line in
                Catalogsanddates(catalog: line)
            }.sorted { cat1, cat2 in
                (Int(cat1.catalog.dropFirst(2)) ?? 0) > (Int(cat2.catalog.dropFirst(2)) ?? 0)
            }
        }
        mysnapshotdata?.catalogsanddates = catalogsanddates ?? []
    }
}
