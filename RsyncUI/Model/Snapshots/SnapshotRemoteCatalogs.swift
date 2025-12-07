//
//  SnapshotRemoteCatalogs.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 19/09/2023.
//

import Foundation
import OSLog
import RsyncProcess

@MainActor
final class SnapshotRemoteCatalogs {
    var mysnapshotdata: ObservableSnapshotData?
    var catalogsanddates: [SnapshotFolder]?

    func getremotecataloginfo(_ config: SynchronizeConfiguration) {
        let handlers = CreateHandlers().createHandlers(
            fileHandler: { _ in },
            processTermination: processTermination
        )

        let arguments = ArgumentsSnapshotRemoteCatalogs(config: config).remotefilelistarguments()
        let process = RsyncProcess(arguments: arguments,
                                   handlers: handlers,
                                   fileHandler: false)
        do {
            try process.executeProcess()
        } catch let e {
            let error = e
            SharedReference.shared.errorobject?.alert(error: error)
        }
    }

    @discardableResult
    init(config: SynchronizeConfiguration,
         snapshotdata: ObservableSnapshotData) {
        guard config.task == SharedReference.shared.snapshot else { return }
        mysnapshotdata = snapshotdata
        getremotecataloginfo(config)
    }

    func processTermination(stringoutputfromrsync: [String]?, hiddenID _: Int?) {
        if let stringoutputfromrsync {
            let catalogs = TrimOutputForRestore(stringoutputfromrsync).trimmeddata
            catalogsanddates = catalogs?.compactMap { line in
                let item = SnapshotFolder(folder: line)
                return (line.contains("done") == false && line.contains("receiving") == false &&
                    line.contains("sent") == false && line.contains("total") == false &&
                    line.contains("./.") == false && line.isEmpty == false &&
                    line.contains("speedup") == false && line.contains("bytes") == false) ? item : nil
            }.sorted { cat1, cat2 in
                (Int(cat1.folder.dropFirst(2)) ?? 0) > (Int(cat2.folder.dropFirst(2)) ?? 0)
            }
        }
        mysnapshotdata?.snapshotfolders = catalogsanddates ?? []
    }
}
