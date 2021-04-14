//
//  ObserveableReferenceRestore.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 06/04/2021.
//
// swiftlint:disable line_length

import Combine
import Foundation

final class ObserveableReferenceRestore: ObservableObject {
    @Published var pathforrestore: String = ""
    @Published var filestorestore: String = ""
    // Copy files from selecting row from view output
    // If in "files" mode copy value to filestorestore
    @Published var filestorestorefromview: String = ""
    @Published var filterstring: String = ""
    @Published var selectedconfig: Configuration?
    @Published var gettingfilelist: Bool = false
    @Published var numberoffiles: Int = 0
    @Published var dryrun: Bool = true
    // Value to check if input field is changed by user
    @Published var inputchangedbyuser: Bool = false

    // Combine
    var subscriptions = Set<AnyCancellable>()
    var outputprocess: OutputProcess?
    var files: Bool = false

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
        $filestorestorefromview
            .debounce(for: .seconds(1), scheduler: globalMainQueue)
            .sink { [unowned self] file in
                if self.files == true {
                    filestorestore = file
                }
            }.store(in: &subscriptions)
        $filestorestore
            .debounce(for: .seconds(1), scheduler: globalMainQueue)
            .sink { _ in
            }.store(in: &subscriptions)
        $filterstring
            .debounce(for: .seconds(2), scheduler: globalMainQueue)
            .sink { [unowned self] _ in
                reloadfiles()
            }.store(in: &subscriptions)
        $selectedconfig
            .sink { [unowned self] config in
                // Only one process at time
                // If change selection abort process
                guard SharedReference.shared.process == nil else {
                    _ = InterruptProcess()
                    return
                }
                if let config = config { validatetaskandgetfilelist(config) }
            }.store(in: &subscriptions)
    }
}

extension ObserveableReferenceRestore {
    func processtermination() {
        numberoffiles = outputprocess?.trimoutput(trim: .one)?.filter { filterstring.isEmpty ? true : $0.contains(filterstring) }.count ?? 0
        gettingfilelist = false
    }

    func filehandler() {}

    // Validate task for remote restore and remote filelist
    func validatetaskandgetfilelist(_ config: Configuration) {
        do {
            let ok = try validatetask(config)
            if ok { getfilelist(config) }
        } catch let e {
            let error = e
            self.propogateerror(error: error)
        }
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
            self.propogateerror(error: error)
        }
    }

    private func validatepath(_ path: String) throws -> Bool {
        if FileManager.default.fileExists(atPath: path, isDirectory: nil) == false {
            throw Validatedpath.nopath
        }
        return true
    }

    func reloadfiles() {
        guard inputchangedbyuser == true else { return }
        if files {
            numberoffiles = outputprocess?.trimoutput(trim: .one)?.filter { filterstring.isEmpty ? true : $0.contains(filterstring) }.count ?? 0
        } else {
            numberoffiles = outputprocess?.trimoutput(trim: .two)?.filter { filterstring.isEmpty ? true : $0.contains(filterstring) }.count ?? 0
        }
    }

    func getfilelist(_ config: Configuration) {
        gettingfilelist = true
        files = true
        let arguments = RestorefilesArguments(task: .rsyncfilelistings,
                                              config: config,
                                              remoteFile: nil,
                                              localCatalog: nil,
                                              drynrun: nil).getArguments()
        outputprocess = OutputProcess()
        let command = RsyncProcessCmdCombineClosure(arguments: arguments,
                                                    config: config,
                                                    processtermination: processtermination,
                                                    filehandler: filehandler)
        command.executeProcess(outputprocess: outputprocess)
    }

    func restore(_ config: Configuration) {
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
                    gettingfilelist = true
                    outputprocess = OutputProcess()
                    let command = RsyncProcessCmdCombineClosure(arguments: arguments,
                                                                config: config,
                                                                processtermination: processtermination,
                                                                filehandler: filehandler)
                    command.executeProcess(outputprocess: outputprocess)
                }
            }
        } catch let e {
            let error = e
            self.propogateerror(error: error)
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

    func getoutput() -> [String]? {
        if files {
            return outputprocess?.trimoutput(trim: .one)?.filter { filterstring.isEmpty ? true : $0.contains(filterstring) }
        } else {
            return outputprocess?.trimoutput(trim: .two)?.filter { filterstring.isEmpty ? true : $0.contains(filterstring) }
        }
    }
}

extension ObserveableReferenceRestore: PropogateError {
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
            return NSLocalizedString("Restore not allowed for syncremote task", comment: "Restore") + "..."
        case .notvalidrestore:
            return NSLocalizedString("Either is path for restore or file to restore empty", comment: "Restore") + "..."
        }
    }
}

/* Logging runtime
 let start = CFAbsoluteTimeGetCurrent()
 let diff = CFAbsoluteTimeGetCurrent() - start
 print("filter filenames: \(diff) seconds")
 print("number of lines: \(remotefilelist?.count ?? 0)")
 */
