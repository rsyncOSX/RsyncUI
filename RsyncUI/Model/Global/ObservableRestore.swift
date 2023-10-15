//
//  ObserveableRestore.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 06/04/2021.
//
// swiftlint:disable line_length

import Combine
import Foundation

final class ObservableRestore: ObservableObject {
    @Published var pathforrestore: String = ""
    @Published var selectedrowforrestore: String = ""

    @Published var restorefilesinprogress: Bool = false
    @Published var numberoffiles: Int = 0
    @Published var dryrun: Bool = true
    @Published var presentsheetrsync = false
    // Value to check if input field is changed by user
    @Published var inputchangedbyuser: Bool = false
    // Alerts
    @Published var alerterror: Bool = false
    @Published var error: Error = Validatedpath.noerror
    // Filenames in restore
    @Published var datalist: [RestoreFileRecord] = []
    @Published var filestorestore: String = ""

    var rsyncdata: [String]?
    var arguments: [String]?
    var selectedconfig: Configuration?
    // Combine
    var subscriptions = Set<AnyCancellable>()

    var rsync: String {
        return GetfullpathforRsync().rsyncpath ?? ""
    }

    init() {
        $inputchangedbyuser
            .sink { _ in
            }.store(in: &subscriptions)
        $dryrun
            .sink { _ in
            }.store(in: &subscriptions)
        $pathforrestore
            .sink { [unowned self] path in
                validatepathforrestore(path)
            }.store(in: &subscriptions)
        $selectedrowforrestore
            .sink { [unowned self] file in
                filestorestore = file
            }.store(in: &subscriptions)
        $presentsheetrsync
            .sink { _ in
            }.store(in: &subscriptions)
    }
}

extension ObservableRestore {
    func processtermination(data: [String]?) {
        rsyncdata = data
        restorefilesinprogress = false
        presentsheetrsync = true
    }

    private func validatetask(_ config: Configuration) throws -> Bool {
        if config.task != SharedReference.shared.syncremote {
            return true
        } else {
            throw RestoreError.notvalidtaskforrestore
        }
    }

    // Validate path for restore
    func validatepathforrestore(_ atpath: String) {
        guard inputchangedbyuser == true else { return }
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
        if FileManager.default.fileExists(atPath: path, isDirectory: nil) == false {
            throw Validatedpath.nopath
        }
        return true
    }

    @MainActor
    func restore() async {
        var arguments: [String]?
        do {
            let ok = try validateforrestore()
            if ok {
                arguments = computerestorearguments(forDisplay: false)
                if let arguments = arguments {
                    restorefilesinprogress = true
                    let command = RsyncAsync(arguments: arguments,
                                             processtermination: processtermination)
                    await command.executeProcess()
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

    private func verifyrestorefile(_ config: Configuration, _: String) -> String {
        // Restore file or catalog
        // drop "./" in filetorestore
        // verify there is a "/" between config.offsiteCatalog + "/" + filestorestore.dropFirst(2)
        // normal is to append a "/" to config.offsiteCatalog but must verify
        // This is a hack for restore of files from last snapshot. Only files from the
        // last snapshot is allowed. The other fix is within the ArgumentsRestore class.
        // Restore arguments
        if config.offsiteCatalog.hasSuffix("/") {
            return config.offsiteCatalog + filestorestore.dropFirst(2) // drop first "./"
        } else {
            return config.offsiteCatalog + "/" + filestorestore.dropFirst(2) // drop first "./"
        }
    }

    private func verifyrestorefilesnapshot(_ config: Configuration, _: String) -> String? {
        // Restore file or catalog
        // drop "./" in filetorestore
        // verify there is a "/" between config.offsiteCatalog + "/" + filestorestore.dropFirst(2)
        // normal is to append a "/" to config.offsiteCatalog but must verify
        // This is a hack for restore of files from last snapshot. Only files from the
        // last snapshot is allowed. The other fix is within the ArgumentsRestore class.
        // Restore arguments
        if config.offsiteCatalog.hasSuffix("/") {
            if let snapshotnum = selectedconfig?.snapshotnum {
                return config.offsiteCatalog + String(snapshotnum - 1) + "/" + filestorestore.dropFirst(2)
            } else {
                return ""
            }
        } else {
            if let snapshotnum = selectedconfig?.snapshotnum {
                return config.offsiteCatalog + String(snapshotnum - 1) + "/" + filestorestore.dropFirst(2) // drop first "./"
            } else {
                return ""
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
            return "Restore not allowed for syncremote task"
        case .notvalidrestore:
            return "Either is path for restore or file to restore empty"
        }
    }
}

// swiftlint:enable line_length
