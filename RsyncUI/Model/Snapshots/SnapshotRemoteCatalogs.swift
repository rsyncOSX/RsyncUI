//
//  SnapshotRemoteCatalogs.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 19/09/2023.
//

import Foundation

@MainActor
final class SnapshotRemoteCatalogs {
    var mysnapshotdata: ObservableSnapshotData?
    var catalogsanddates: [Catalogsanddates]?

    func getremotecataloginfo(_ config: SynchronizeConfiguration) {
        let arguments = ArgumentsSnapshotRemoteCatalogs(config: config).remotefilelistarguments()
        let command = ProcessRsync(arguments: arguments,
                                   processtermination: processtermination)
        command.executeProcess()
    }

    @discardableResult
    init(config: SynchronizeConfiguration,
         snapshotdata: ObservableSnapshotData)
    {
        guard config.task == SharedReference.shared.snapshot else { return }
        mysnapshotdata = snapshotdata
        getremotecataloginfo(config)
    }

    func processtermination(stringoutputfromrsync: [String]?, hiddenID _: Int?) {
        if let stringoutputfromrsync {
            let catalogs = TrimOutputForRestore(stringoutputfromrsync).trimmeddata
            catalogsanddates = catalogs?.compactMap { line in
                let item = Catalogsanddates(catalog: line)
                return (line.contains("done") == false && line.contains("receiving") == false &&
                    line.contains("sent") == false && line.contains("total") == false &&
                    line.contains("./.") == false && line.isEmpty == false &&
                    line.contains("speedup") == false && line.contains("bytes") == false) ? item : nil
            }.sorted { cat1, cat2 in
                (Int(cat1.catalog.dropFirst(2)) ?? 0) > (Int(cat2.catalog.dropFirst(2)) ?? 0)
            }
        }
        mysnapshotdata?.catalogsanddates = catalogsanddates ?? []
    }
}
