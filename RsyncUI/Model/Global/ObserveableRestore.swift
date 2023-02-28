//
//  ObserveableRestore.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 06/04/2021.
//
// swiftlint:disable line_length

import Combine
import Foundation

final class ObserveableRestore: ObservableObject {
    @Published var pathforrestore: String = ""
    @Published var filestorestorefromrestorefilesview: String = ""
    @Published var selectedconfig: Configuration?
    @Published var restorefilesinprogress: Bool = false
    @Published var numberoffiles: Int = 0
    @Published var dryrun: Bool = true
    // Value to check if input field is changed by user
    @Published var inputchangedbyuser: Bool = false

    // Combine
    var subscriptions = Set<AnyCancellable>()
    var files: Bool = false
    var rsyncdata: [String]?
    var filestorestore: String = ""

    init() {
        $inputchangedbyuser
            .sink { _ in
            }.store(in: &subscriptions)
        $dryrun
            .sink { _ in
            }.store(in: &subscriptions)
        $pathforrestore
            .debounce(for: .seconds(1), scheduler: globalMainQueue)
            .sink { [unowned self] path in
                validatepathforrestore(path)
            }.store(in: &subscriptions)
        $filestorestorefromrestorefilesview
            .sink { [unowned self] file in
                if self.files == true {
                    filestorestore = file
                }
            }.store(in: &subscriptions)
        $selectedconfig
            .sink { _ in
            }.store(in: &subscriptions)
    }
}

extension ObserveableRestore {
    func processtermination(data: [String]?) {
        restorefilesinprogress = false
        rsyncdata = data
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
            let error = e
            propogateerror(error: error)
        }
    }

    private func validatepath(_ path: String) throws -> Bool {
        if FileManager.default.fileExists(atPath: path, isDirectory: nil) == false {
            throw Validatedpath.nopath
        }
        return true
    }

    @MainActor
    func restore(_ config: Configuration) async {
        files = false
        var arguments: [String]?
        do {
            let ok = try validateforrestore()
            if ok {
                if filestorestore == "./." {
                    // full restore
                    arguments = ArgumentsRestore(config: config).argumentsrestore(dryRun: dryrun, forDisplay: false, tmprestore: true)
                } else {
                    // Restore file or catalog
                    var localconf = config
                    localconf.offsiteCatalog = verifyrestorefile(config, filestorestore)
                    arguments = ArgumentsRestore(config: localconf).argumentsrestore(dryRun: dryrun, forDisplay: false, tmprestore: true)
                }
                if let arguments = arguments {
                    restorefilesinprogress = true
                    let command = RsyncAsync(arguments: arguments,
                                             processtermination: processtermination)
                    await command.executeProcess()
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

    private func verifyrestorefile(_ config: Configuration, _: String) -> String {
        // Restore file or catalog
        // drop "./" in filetorestore
        // verify there is a "/" between config.offsiteCatalog + "/" + filestorestore.dropFirst(2)
        // normal is to append a "/" to config.offsiteCatalog but must verify
        if config.offsiteCatalog.hasSuffix("/") {
            return config.offsiteCatalog + filestorestore.dropFirst(2) // drop first "./"
        } else {
            return config.offsiteCatalog + "/" + filestorestore.dropFirst(2) // drop first "./"
        }
    }
}

extension ObserveableRestore {
    func propogateerror(error: Error) {
        SharedReference.shared.errorobject?.propogateerror(error: error)
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

/* Logging runtime
 let start = CFAbsoluteTimeGetCurrent()
 let diff = CFAbsoluteTimeGetCurrent() - start
 print("filter filenames: \(diff) seconds")
 print("number of lines: \(remotefilelist?.count ?? 0)")
 */
