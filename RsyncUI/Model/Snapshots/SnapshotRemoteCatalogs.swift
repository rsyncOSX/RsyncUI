//
//  SnapshotRemoteCatalogs.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 19/09/2023.
//

import Foundation
import OSLog
import RsyncProcessStreaming

@MainActor
final class SnapshotRemoteCatalogs {
    var mysnapshotdata: ObservableSnapshotData?
    var catalogsanddates: [SnapshotFolder]?

    // Streaming strong references
    private var streamingHandlers: RsyncProcessStreaming.ProcessHandlers?
    private var activeStreamingProcess: RsyncProcessStreaming.RsyncProcess?

    func getremotecataloginfo(_ config: SynchronizeConfiguration) {
        streamingHandlers = CreateStreamingHandlers().createHandlers(
            fileHandler: { _ in },
            processTermination: processTermination
        )

        let arguments = ArgumentsSnapshotRemoteCatalogs(config: config).remotefilelistarguments()
        guard let arguments else { return }
        guard let streamingHandlers else { return }

        let process = RsyncProcessStreaming.RsyncProcess(
            arguments: arguments,
            handlers: streamingHandlers,
            useFileHandler: false
        )
        do {
            try process.executeProcess()
            activeStreamingProcess = process
        } catch let err {
            let error = err
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
