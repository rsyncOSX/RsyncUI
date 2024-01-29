//
//  Snapshotcatalogs.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 19/09/2023.
//

import Foundation

class Snapshotcatalogs {
    var mysnapshotdata: SnapshotData?
    var catalogsanddates: [Catalogsanddates]?

    @MainActor
    func getremotecataloginfo(_ config: SynchronizeConfiguration) async {
        let arguments = RestorefilesArguments(task: .snapshotcatalogsonly,
                                              config: config,
                                              remoteFile: nil,
                                              localCatalog: nil,
                                              drynrun: nil,
                                              snapshot: true)
        let command = RsyncAsync(arguments: arguments.getArguments(),
                                 processtermination: processtermination)
        await command.executeProcess()
    }

    // Getting, from process, remote snapshotcatalogs
    // sort snapshotcatalogs
    func prepareremotesnapshotcatalogs(data: [String]?) {
        // Check for split lines and merge lines if true
        let data = PrepareOutput(data ?? [])
        if data.splitlines { data.alignsplitlines() }
        var catalogs = TrimOne(data.trimmeddata).trimmeddata
        // var datescatalogs = TrimFour(data.trimmeddata).trimmeddata
        // drop index where row = "./."
        if let index = catalogs.firstIndex(where: { $0 == "./." }) {
            catalogs.remove(at: index)
            // datescatalogs.remove(at: index)
        }
        catalogsanddates = [Catalogsanddates]()
        // let dateformatter = DateFormatter()
        // dateformatter.dateFormat = "YYYY/mm/dd"
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
        Task {
            await getremotecataloginfo(config)
        }
    }

    func processtermination(data: [String]?) {
        prepareremotesnapshotcatalogs(data: data)
        mysnapshotdata?.catalogsanddates = catalogsanddates ?? []
    }

    func filehandler() {}
}
