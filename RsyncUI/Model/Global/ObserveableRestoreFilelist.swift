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
    @Published var filterstring: String = ""
    @Published var gettingfilelist: Bool = false
    @Published var inputchangedbyuser: Bool = false
    // Combine
    var subscriptions = Set<AnyCancellable>()
    var files: Bool = false
    var rsyncdata: [String]?
    var numberoffiles: Int = 0
    var filestorestore: String = ""

    init() {
        $inputchangedbyuser
            .sink { _ in
            }.store(in: &subscriptions)
        $filterstring
            .debounce(for: .seconds(1), scheduler: globalMainQueue)
            .sink { [unowned self] _ in
                reloadfiles()
            }.store(in: &subscriptions)
    }
}

extension ObserveableRestoreFilelist {
    func processtermination(data: [String]?) {
        numberoffiles = TrimOne(data ?? []).trimmeddata.filter { filterstring.isEmpty ? true : $0.contains(filterstring) }.count
        gettingfilelist = false
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
