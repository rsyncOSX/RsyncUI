//
//  Snapshotcatalogs.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 19/09/2023.
//
// swiftlint: disable line_length

import Foundation
import OSLog

@MainActor
class Snapshotcatalogs {
    var mysnapshotdata: SnapshotData?
    var catalogsanddates: [Catalogsanddates]?

    func getremotecataloginfo(_ config: SynchronizeConfiguration) {
        let arguments = ArgumentsRemoteFileList(config: config, filelisttask: .snapshotcatalogsonly).remotefilelistarguments()
        let command = RsyncProcessNOFilehandler(arguments: arguments,
                                                processtermination: processtermination)
        command.executeProcess()
    }

    // Getting, from process, remote snapshotcatalogs
    // sort snapshotcatalogs
    func prepareremotesnapshotcatalogs(data: [String]?) {
        // Check for split lines and merge lines if true
        let data = PrepareOutput(data ?? [])
        if data.splitlines { data.alignsplitlines() }
        var catalogs = TrimOutputForRestore(data.trimmeddata).trimmeddata
        // A few more cleanups after rimming dats
        // drop index where row = "./."
        if let index = catalogs.firstIndex(where: { $0 == "./done" }) {
            catalogs.remove(at: index)
        }
        if let index = catalogs.firstIndex(where: { $0 == "./." }) {
            catalogs.remove(at: index)
        }
        catalogsanddates = [Catalogsanddates]()
        for i in 0 ..< catalogs.count {
            let item = Catalogsanddates(catalog: catalogs[i])
            catalogsanddates?.append(item)
        }
        catalogsanddates = catalogsanddates?.sorted { cat1, cat2 in
            (Int(cat1.catalog.dropFirst(2)) ?? 0) > (Int(cat2.catalog.dropFirst(2)) ?? 0)
        }
    }

    init(config: SynchronizeConfiguration,
         snapshotdata: SnapshotData)
    {
        guard config.task == SharedReference.shared.snapshot else { return }
        mysnapshotdata = snapshotdata
        getremotecataloginfo(config)
    }

    func processtermination(data: [String]?, hiddenID _: Int?) {
        prepareremotesnapshotcatalogs(data: data)
        mysnapshotdata?.catalogsanddates = catalogsanddates ?? []
    }
}

// swiftlint: enable line_length
