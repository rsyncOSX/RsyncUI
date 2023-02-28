//
//  ObserveableRestoreFilelist.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 06/04/2021.
//
// swiftlint:disable line_length

import Combine
import Foundation

final class ObserveableRestoreFilelist: ObservableObject {
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
    // Number of files restored
    @Published var numberoffilesrestored: Int = 0

    // Combine
    var subscriptions = Set<AnyCancellable>()
    var files: Bool = false
    var rsyncdata: [String]?

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
            .debounce(for: .seconds(1), scheduler: globalMainQueue)
            .sink { [unowned self] _ in
                reloadfiles()
            }.store(in: &subscriptions)
        $selectedconfig
            .sink { [unowned self] config in
                Task {
                    // Only one process at time
                    // If change selection abort process
                    guard SharedReference.shared.process == nil else {
                        _ = InterruptProcess()
                        return
                    }
                    if let config = config { await validatetaskandgetfilelist(config) }
                }

            }.store(in: &subscriptions)
    }
}

extension ObserveableRestoreFilelist {
    func processtermination(data: [String]?) {
        numberoffiles = TrimOne(data ?? []).trimmeddata.filter { filterstring.isEmpty ? true : $0.contains(filterstring) }.count
        gettingfilelist = false
        numberoffilesrestored = 0
        rsyncdata = data
    }

    // Validate task for remote restore and remote filelist
    func validatetaskandgetfilelist(_ config: Configuration) async {
        do {
            let ok = try validatetask(config)
            if ok { await getfilelist(config) }
        } catch let e {
            let error = e
            propogateerror(error: error)
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
            propogateerror(error: error)
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
            numberoffiles = TrimOne(rsyncdata ?? []).trimmeddata.filter { filterstring.isEmpty ? true : $0.contains(filterstring) }.count
        } else {
            numberoffiles = TrimTwo(rsyncdata ?? []).trimmeddata.filter { filterstring.isEmpty ? true : $0.contains(filterstring) }.count
        }
    }

    @MainActor
    func getfilelist(_ config: Configuration) async {
        gettingfilelist = true
        files = true
        let arguments = RestorefilesArguments(task: .rsyncfilelistings,
                                              config: config,
                                              remoteFile: nil,
                                              localCatalog: nil,
                                              drynrun: nil).getArguments()
        let command = RsyncAsync(arguments: arguments,
                                 processtermination: processtermination)
        await command.executeProcess()
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
                    gettingfilelist = true
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

    func getoutput() -> [String]? {
        if files {
            // trim one
            return TrimOne(rsyncdata ?? []).trimmeddata.filter { filterstring.isEmpty ? true : $0.contains(filterstring) }
        } else {
            // trim two
            return TrimTwo(rsyncdata ?? []).trimmeddata.filter { filterstring.isEmpty ? true : $0.contains(filterstring) }
        }
    }
}

extension ObserveableRestoreFilelist {
    func propogateerror(error: Error) {
        SharedReference.shared.errorobject?.propogateerror(error: error)
    }
}
