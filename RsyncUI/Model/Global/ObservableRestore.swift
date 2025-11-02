//
//  ObservableRestore.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 06/04/2021.
//
// swiftlint:disable line_length

import Foundation
import Observation

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

    func processtermination(stringoutputfromrsync: [String]?, hiddenID _: Int?) {
        Task {
            restorefilelist = await
                ActorCreateOutputforView().createoutputafterrestore(stringoutputfromrsync)
        }
        restorefilesinprogress = false
        presentrestorelist = true
    }

    func verifypathforrestore(_ path: String) -> Bool {
        let fm = FileManager.default
        return fm.fileExists(atPath: path, isDirectory: nil)
    }

    func executerestore() {
        var arguments: [String]?
        do {
            let ok = try validateforrestore()
            if ok {
                arguments = computerestorearguments(forDisplay: false)
                if let arguments {
                    restorefilesinprogress = true

                    if SharedReference.shared.rsyncversion3 {
                        let process = ProcessRsyncVer3x(arguments: arguments,
                                                        processtermination: processtermination,
                                                        rsyncpath: GetfullpathforRsync().rsyncpath,
                                                        checklineforerror: TrimOutputFromRsync().checkforrsyncerror)
                        process.executeProcess()
                    } else {
                        let process = ProcessRsyncOpenrsync(arguments: arguments,
                                                            processtermination: processtermination)
                        process.executeProcess()
                    }
                }
            }
        } catch let e {
            let error = e
            propogateerror(error: error)
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
                return ArgumentsRestore(config: config, restoresnapshotbyfiles: false).argumentsrestore(dryRun: dryrun, forDisplay: forDisplay)
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
                    return ArgumentsRestore(config: localconf, restoresnapshotbyfiles: true).argumentsrestore(dryRun: dryrun, forDisplay: forDisplay)
                } else {
                    // Arguments for full restore from last snapshot
                    return ArgumentsRestore(config: localconf, restoresnapshotbyfiles: false).argumentsrestore(dryRun: dryrun, forDisplay: forDisplay)
                }
            }
        }
        return nil
    }

    func propogateerror(error: Error) {
        SharedReference.shared.errorobject?.alert(error: error)
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

// swiftlint:enable line_length
