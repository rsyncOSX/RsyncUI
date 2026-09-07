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
    var selectedconfig: SynchronizeConfiguration? {
        didSet {
            if oldValue?.id != selectedconfig?.id {
                selectedSnapshot = nil
                clearFileSelection()
            }
        }
    }

    var selectedSnapshot: String? {
        didSet {
            if oldValue != selectedSnapshot {
                clearFileSelection()
            }
        }
    }

    private func clearFileSelection() {
        restorefilelist.removeAll()
        filestorestore = ""
    }

    func configurationForRestore() throws -> SynchronizeConfiguration {
        guard var config = selectedconfig else { throw RestoreError.notvalidrestore }
        if config.task == SharedReference.shared.snapshot, let selectedSnapshot {
            guard selectedSnapshot.hasPrefix("./"),
                  let number = Int(selectedSnapshot.dropFirst(2)), number > 0, number < Int.max else {
                throw RestoreError.notvalidrestore
            }
            config.snapshotnum = number + 1
        }
        return config
    }

    // Progress count
    var progress: Double = 0
    var max: Double = 0

    // Streaming strong references
    private var streamingHandlers: RsyncProcessStreaming.ProcessHandlers?
    private var activeStreamingProcess: RsyncProcessStreaming.RsyncProcess?

    func processTermination(stringoutputfromrsync: [String]?, hiddenID _: Int?, outcome: StreamingProcessOutcome) {
        if dryrun {
            max = Double(stringoutputfromrsync?.count ?? 0)
        }
        restorefilelist = CreateOutputforView().createoutputafterrestore(stringoutputfromrsync)
        restorefilesinprogress = false
        presentrestorelist = outcome == .success
        // Release streaming references to avoid retain cycles
        activeStreamingProcess = nil
        streamingHandlers = nil
    }

    func files(matching query: String) -> [RsyncOutputData] {
        query.isEmpty ? restorefilelist : restorefilelist.filter { $0.record.localizedStandardContains(query) }
    }

    func verifyPathForRestore(_ path: String) -> Bool {
        (try? Self.validatedDestination(path)) != nil
    }

    static func validatedDestination(_ path: String) throws -> String {
        let expanded = (path as NSString).expandingTildeInPath
        var isDirectory: ObjCBool = false
        guard expanded.hasPrefix("/"),
              FileManager.default.fileExists(atPath: expanded, isDirectory: &isDirectory),
              isDirectory.boolValue,
              FileManager.default.isWritableFile(atPath: expanded) else { throw RestoreError.invalidDestination }
        return expanded.hasSuffix("/") ? expanded : expanded + "/"
    }

    var canRestore: Bool {
        !restorefilesinprogress && !filestorestore.isEmpty && verifyPathForRestore(pathforrestore)
    }

    func executeRestore() {
        guard !restorefilesinprogress, SharedReference.shared.process == nil else { return }
        do {
            guard SharedReference.shared.norsync == false else { throw Validatedrsync.norsync }
            let arguments = try restoreArguments(forDisplay: false)
            streamingHandlers = CreateStreamingHandlers().createResultHandlers(
                fileHandler: { [weak self] count in self?.fileHandler(count: count) },
                processTermination: { [weak self] output, hiddenID, outcome in
                    self?.processTermination(stringoutputfromrsync: output, hiddenID: hiddenID, outcome: outcome)
                }
            )
            guard let streamingHandlers else { return }
            let process = RsyncProcessStreaming.RsyncProcess(arguments: arguments,
                                                             handlers: streamingHandlers,
                                                             useFileHandler: true)
            restorefilesinprogress = true
            progress = 0
            activeStreamingProcess = process
            try process.executeProcess()
        } catch {
            restorefilesinprogress = false
            activeStreamingProcess = nil
            streamingHandlers = nil
            propagateError(error: error)
        }
    }

    /// Validate and construct the command from one snapshot of the visible destination.
    func restoreArguments(forDisplay: Bool) throws -> [String] {
        let destination = try Self.validatedDestination(pathforrestore)
        guard !filestorestore.isEmpty, let selectedconfig,
              selectedconfig.task != SharedReference.shared.syncremote,
              selectedconfig.task != SharedReference.shared.halted else { throw RestoreError.notvalidrestore }
        guard let arguments = computerestorearguments(forDisplay: forDisplay, destination: destination) else {
            throw RestoreError.notvalidrestore
        }
        return arguments
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
            if let snapshotnum = config.snapshotnum {
                config.offsiteCatalog + String(snapshotnum - 1).appending("/") + filestorestore.dropFirst(2)
            } else {
                ""
            }
        } else {
            if let snapshotnum = config.snapshotnum {
                config.offsiteCatalog + String(snapshotnum - 1).appending("/") + filestorestore.dropFirst(2) // drop first "./"
            } else {
                ""
            }
        }
    }

    private func computerestorearguments(forDisplay: Bool, destination: String) -> [String]? {
        // Restore arguments
        // Full restore
        if filestorestore == "./." {
            if let config = try? configurationForRestore() {
                return ArgumentsRestore(config: config, restoresnapshotbyfiles: false, destination: destination).argumentsrestore(dryRun: dryrun,
                                                                                                                                  forDisplay: forDisplay)
            }
        } else {
            // Restore by file
            if var localconf = try? configurationForRestore() {
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
                                            restoresnapshotbyfiles: true, destination: destination).argumentsrestore(dryRun: dryrun,
                                                                                                                     forDisplay: forDisplay)
                } else {
                    // Arguments for full restore from last snapshot
                    return ArgumentsRestore(config: localconf,
                                            restoresnapshotbyfiles: false, destination: destination).argumentsrestore(dryRun: dryrun,
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
    case invalidDestination

    var errorDescription: String? {
        switch self {
        case .notvalidtaskforrestore:
            "Restore not allowed for syncremote task"
        case .notvalidrestore:
            "Select a valid task and files to restore."
        case .invalidDestination:
            "Choose an existing, writable destination folder for restored files."
        }
    }
}
