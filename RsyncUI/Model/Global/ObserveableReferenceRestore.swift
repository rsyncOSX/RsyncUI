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
    @Published var filterstring: String = ""
    @Published var selectedconfig: Configuration?
    @Published var gettingfilelist: Bool = false
    @Published var numberoffiles: Int = 0
    // Value to check if input field is changed by user
    @Published var inputchangedbyuser: Bool = false

    // Combine
    var subscriptions = Set<AnyCancellable>()
    var outputprocess: OutputProcess?

    init() {
        $inputchangedbyuser
            .sink { _ in
            }.store(in: &subscriptions)
        $pathforrestore
            .debounce(for: .seconds(1), scheduler: globalMainQueue)
            .sink { [unowned self] path in
                validatepathforrestore(path)
            }.store(in: &subscriptions)
        $filestorestore
            .debounce(for: .seconds(1), scheduler: globalMainQueue)
            .sink { [unowned self] path in
                validatefilestorestore(path)
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

    func validatefilestorestore(_: String) {}

    func reloadfiles() {
        guard inputchangedbyuser == true else { return }
        numberoffiles = outputprocess?.trimoutput(trim: .one)?.filter { filterstring.isEmpty ? true : $0.contains(filterstring) }.count ?? 0
    }

    func getfilelist(_ config: Configuration) {
        gettingfilelist = true
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
        var arguments: [String]?
        if filestorestore == "./." {
            // full restore
            arguments = ArgumentsRestore(config: config).argumentsrestore(dryRun: true, forDisplay: false, tmprestore: true)
        } else {
            var localconf = config
            localconf.offsiteCatalog = config.offsiteCatalog + filestorestore
            arguments = ArgumentsRestore(config: localconf).argumentsrestore(dryRun: true, forDisplay: false, tmprestore: true)
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

    func getoutput() -> [String]? {
        return outputprocess?.trimoutput(trim: .one)?.filter { filterstring.isEmpty ? true : $0.contains(filterstring)
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
    case error1

    var errorDescription: String? {
        switch self {
        case .notvalidtaskforrestore:
            return NSLocalizedString("Restore not allowed for syncremote task", comment: "Restore") + "..."
        case .error1:
            return NSLocalizedString("Error1", comment: "Restore") + "..."
        }
    }
}

/* Logging runtime
 let start = CFAbsoluteTimeGetCurrent()
 let diff = CFAbsoluteTimeGetCurrent() - start
 print("filter filenames: \(diff) seconds")
 print("number of lines: \(remotefilelist?.count ?? 0)")
 */
