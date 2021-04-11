//
//  ObserveableReferenceRestore.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 06/04/2021.
//
// swiftlint:disable line_length

import Combine
import Foundation
import SwiftyBeaver

final class ObserveableReferenceRestore: ObservableObject {
    // When restore is ready set true
    @Published var isReady: Bool = false
    @Published var restorepath: String = ""
    @Published var filestorestore: String = ""
    @Published var typeofrestore = TypeofRestore.byfile
    @Published var filterstring: String = ""
    @Published var selectedconfig: Configuration?
    @Published var gettingfilelist: Bool = false
    @Published var outputprocess: OutputProcess?
    @Published var numberoffiles: Int = 0
    // Combine
    var subscriptions = Set<AnyCancellable>()
    // remote filelist
    var remotefilelist: [String]?

    let log = SwiftyBeaver.self

    init() {
        $restorepath
            .debounce(for: .seconds(1), scheduler: globalMainQueue)
            .sink { [unowned self] path in
                validaterestorepath(path)
            }.store(in: &subscriptions)
        $filestorestore
            .debounce(for: .seconds(1), scheduler: globalMainQueue)
            .sink { [unowned self] path in
                validatefilestorestore(path)
            }.store(in: &subscriptions)
        $typeofrestore
            .sink { [unowned self] type in
                validatetypeofrestore(type)
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
        remotefilelist = outputprocess?.trimoutput(trim: .one)?.filter { filterstring.isEmpty ? true : $0.contains(filterstring) }
        numberoffiles = remotefilelist?.count ?? 0
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

    func validaterestorepath(_: String) {}

    func validatefilestorestore(_: String) {}

    func validatetypeofrestore(_: TypeofRestore) {}

    func reloadfiles() {
        let start = CFAbsoluteTimeGetCurrent()
        remotefilelist = outputprocess?.trimoutput(trim: .one)?.filter { filterstring.isEmpty ? true : $0.contains(filterstring) }
        numberoffiles = remotefilelist?.count ?? 0
        // Logg
        let diff = CFAbsoluteTimeGetCurrent() - start
        log.info("filter filenames: \(diff) seconds")
        log.info("number of lines: \(remotefilelist?.count ?? 0)")
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
                                                    config: nil,
                                                    processtermination: processtermination,
                                                    filehandler: filehandler)
        command.executeProcess(outputprocess: outputprocess)
    }

    func getoutput() -> [Outputrecord]? {
        guard remotefilelist?.count ?? 0 > 0 else { return nil }
        var transformedoutput = [Outputrecord]()
        for i in 0 ..< (remotefilelist?.count ?? 0) {
            transformedoutput.append(Outputrecord(line: remotefilelist?[i] ?? ""))
        }
        return transformedoutput
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
