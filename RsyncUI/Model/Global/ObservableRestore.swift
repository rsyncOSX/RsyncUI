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
    var presentsheetrsync = false
    // Value to check if input field is changed by user
    var inputchangedbyuser: Bool = false
    // Alerts
    var alerterror: Bool = false
    var error: Error = Validatedpath.noerror
    // Filenames in restore
    var datalist: [RestoreFileRecord] = []
    var filestorestore: String = ""
    @ObservationIgnored var rsyncdata: [String]?
    var selectedconfig: SynchronizeConfiguration?

    func processtermination(data: [String]?, hiddenID _: Int?) {
        rsyncdata = data
        restorefilesinprogress = false
        presentsheetrsync = true
    }

    // Validate path for restore
    func validatepathforrestore(_ atpath: String) {
        guard atpath.isEmpty == false else { return }
        do {
            let ok = try validatepath(atpath)
            if ok {
                SharedReference.shared.pathforrestore = atpath
            }
        } catch let e {
            error = e
            alerterror = true
        }
    }

    private func validatepath(_ path: String) throws -> Bool {
        let fm = FileManager.default
        if fm.fileExists(atPath: path, isDirectory: nil) == false {
            throw Validatedpath.nopath
        }
        return true
    }

    func executerestore() {
        var arguments: [String]?
        do {
            let ok = try validateforrestore()
            if ok {
                arguments = computerestorearguments(forDisplay: false)
                if let arguments {
                    restorefilesinprogress = true
                    let command = RsyncProcessNOFilehandler(arguments: arguments,
                                                            processtermination: processtermination)
                    command.executeProcess()
                }
            }
        } catch let e {
            error = e
            alerterror = true
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
        // verify there is a "/" between config.offsiteCatalog + "/" + filestorestore.dropFirst(2)
        // normal is to append a "/" to config.offsiteCatalog but must verify
        // This is a hack for restore of files from last snapshot. Only files from the
        // last snapshot is allowed. The other fix is within the ArgumentsRestore class.
        // Restore arguments
        if config.offsiteCatalog.hasSuffix("/") {
            config.offsiteCatalog + filestorestore.dropFirst(2) // drop first "./"
        } else {
            config.offsiteCatalog + "/" + filestorestore.dropFirst(2) // drop first "./"
        }
    }

    private func verifyrestorefilesnapshot(_ config: SynchronizeConfiguration, _: String) -> String? {
        // Restore file or catalog
        // drop "./" in filetorestore
        // verify there is a "/" between config.offsiteCatalog + "/" + filestorestore.dropFirst(2)
        // normal is to append a "/" to config.offsiteCatalog but must verify
        // This is a hack for restore of files from last snapshot. Only files from the
        // last snapshot is allowed. The other fix is within the ArgumentsRestore class.
        // Restore arguments
        if config.offsiteCatalog.hasSuffix("/") {
            if let snapshotnum = selectedconfig?.snapshotnum {
                config.offsiteCatalog + String(snapshotnum - 1) + "/" + filestorestore.dropFirst(2)
            } else {
                ""
            }
        } else {
            if let snapshotnum = selectedconfig?.snapshotnum {
                config.offsiteCatalog + String(snapshotnum - 1) + "/" + filestorestore.dropFirst(2) // drop first "./"
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
                return ArgumentsRestore(config: config, restoresnapshotbyfiles: false).argumentsrestore(dryRun: dryrun, forDisplay: forDisplay, tmprestore: true)
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
                    return ArgumentsRestore(config: localconf, restoresnapshotbyfiles: true).argumentsrestore(dryRun: dryrun, forDisplay: forDisplay, tmprestore: true)
                } else {
                    // Arguments for full restore from last snapshot
                    return ArgumentsRestore(config: localconf, restoresnapshotbyfiles: false).argumentsrestore(dryRun: dryrun, forDisplay: forDisplay, tmprestore: true)
                }
            }
        }
        return nil
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
