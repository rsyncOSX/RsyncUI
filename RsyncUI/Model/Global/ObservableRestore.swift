//
//  ObservableRestore.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 06/04/2021.
//

import Foundation
import Observation
import OSLog
import RsyncProcessStreaming

@Observable @MainActor
final class ObservableRestore {
    var pathforrestore: String = ""
    var restorefilesinprogress: Bool = false
    var numberoffiles: Int = 0
    var dryrun: Bool = true
    var presentrestorelist = false
    // Filenames in restore
    var restorefilelist: [RsyncOutputData] = []
    var filestorestore: String = ""
    var selectedconfig: SynchronizeConfiguration?
    // Progress count
    var progress: Double = 0
    var max: Double = 0

    // Streaming strong references
    private var streamingHandlers: RsyncProcessStreaming.ProcessHandlers?
    private var activeStreamingProcess: RsyncProcessStreaming.RsyncProcess?

    func processTermination(stringoutputfromrsync: [String]?, hiddenID _: Int?) {
        if dryrun {
            max = Double(stringoutputfromrsync?.count ?? 0)
        }
        Task {
            restorefilelist = await
                ActorCreateOutputforView().createoutputafterrestore(stringoutputfromrsync)
        }
        restorefilesinprogress = false
        presentrestorelist = true
    }

    func verifyPathForRestore(_ path: String) -> Bool {
        let fmanager = FileManager.default
        return fmanager.fileExists(atPath: path, isDirectory: nil)
    }

    func executeRestore() {
        var arguments: [String]?
        streamingHandlers = CreateStreamingHandlers().createHandlers(
            fileHandler: fileHandler,
            processTermination: processTermination
        )

        do {
            let isValid = try validateforrestore()
            if isValid {
                arguments = computerestorearguments(forDisplay: false)
                if let arguments {
                    restorefilesinprogress = true

                    // Must check valid rsync exists
                    guard SharedReference.shared.norsync == false else { return }

                    guard let streamingHandlers else { return }

                    let process = RsyncProcessStreaming.RsyncProcess(
                        arguments: arguments,
                        handlers: streamingHandlers,
                        useFileHandler: true
                    )
                    do {
                        progress = 0
                        try process.executeProcess()
                        activeStreamingProcess = process
                    } catch let err {
                        let error = err
                        SharedReference.shared.errorobject?.alert(error: error)
                    }
                }
            }
        } catch let err {
            let error = err
            propagateError(error: error)
        }
    }

    private func validateforrestore() throws -> Bool {
        if filestorestore.isEmpty == true || (SharedReference.shared.pathforrestore?.isEmpty ?? true) == true {
            throw RestoreError.notvalidrestore
        }
        return true
    }

    private func verifyrestorefile(_ config: SynchronizeConfiguration, _: String) -> String {
        // Restore file or catalog
        // drop "./" in filetorestore
        // verify there is a "/" between config.offsiteCatalog.appending("/") + filestorestore.dropFirst(2)
        // normal is to append a "/" to config.offsiteCatalog but must verify
        // This is a hack for restore of files from last snapshot. Only files from the
        // last snapshot is allowed. The other fix is within the ArgumentsRestore class.
        // Restore arguments
        if config.offsiteCatalog.hasSuffix("/") {
            config.offsiteCatalog + filestorestore.dropFirst(2) // drop first "./"
        } else {
            config.offsiteCatalog.appending("/") + filestorestore.dropFirst(2) // drop first "./"
        }
    }

    private func verifyrestorefilesnapshot(_ config: SynchronizeConfiguration, _: String) -> String? {
        // Restore file or catalog
        // drop "./" in filetorestore
        // verify there is a "/" between config.offsiteCatalog.appending("/") + filestorestore.dropFirst(2)
        // normal is to append a "/" to config.offsiteCatalog but must verify
        // This is a hack for restore of files from last snapshot. Only files from the
        // last snapshot is allowed. The other fix is within the ArgumentsRestore class.
        // Restore arguments
        if config.offsiteCatalog.hasSuffix("/") {
            if let snapshotnum = selectedconfig?.snapshotnum {
                config.offsiteCatalog + String(snapshotnum - 1).appending("/") + filestorestore.dropFirst(2)
            } else {
                ""
            }
        } else {
            if let snapshotnum = selectedconfig?.snapshotnum {
                config.offsiteCatalog + String(snapshotnum - 1).appending("/") + filestorestore.dropFirst(2) // drop first "./"
            } else {
                ""
            }
        }
    }

    private func computerestorearguments(forDisplay: Bool) -> [String]? {
        // Restore arguments
        // Full restore
        if filestorestore == "./." {
            if let config = selectedconfig {
                return ArgumentsRestore(config: config, restoresnapshotbyfiles: false).argumentsrestore(dryRun: dryrun,
                                                                                                        forDisplay: forDisplay)
            }
        } else {
            // Restore by file
            if var localconf = selectedconfig {
                let snapshot: Bool = (localconf.snapshotnum != nil) ? true : false
                if snapshot {
                    localconf.offsiteCatalog = verifyrestorefilesnapshot(localconf, filestorestore) ?? ""
                    guard localconf.offsiteCatalog.isEmpty == false else { return nil }
                } else {
                    localconf.offsiteCatalog = verifyrestorefile(localconf, filestorestore)
                }
                if snapshot {
                    // Arguments for restore file from last snapshot
                    return ArgumentsRestore(config: localconf,
                                            restoresnapshotbyfiles: true).argumentsrestore(dryRun: dryrun,
                                                                                           forDisplay: forDisplay)
                } else {
                    // Arguments for full restore from last snapshot
                    return ArgumentsRestore(config: localconf,
                                            restoresnapshotbyfiles: false).argumentsrestore(dryRun: dryrun,
                                                                                            forDisplay: forDisplay)
                }
            }
        }
        return nil
    }

    func propagateError(error: Error) {
        SharedReference.shared.errorobject?.alert(error: error)
    }

    func fileHandler(count: Int) {
        progress = Double(count)
    }
}

enum RestoreError: LocalizedError {
    case notvalidtaskforrestore
    case notvalidrestore

    var errorDescription: String? {
        switch self {
        case .notvalidtaskforrestore:
            "Restore not allowed for syncremote task"
        case .notvalidrestore:
            "Either is path for restore or file to restore empty"
        }
    }
}
