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
    var rsyncdata: [String]?
    var numberoffiles: Int = 0
    var filestorestore: String = ""

    init() {
        $inputchangedbyuser
            .sink { _ in
            }.store(in: &subscriptions)
        $filterstring
            .debounce(for: .seconds(1), scheduler: globalMainQueue)
            .sink { _ in
            }.store(in: &subscriptions)
    }
}

extension ObserveableRestoreFilelist {
    func processtermination(data: [String]?) {
        guard data?.count ?? 0 > 0 else { return }
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

    @MainActor
    func getfilelist(_ config: Configuration) async {
        gettingfilelist = true
        let snapshot: Bool = (config.snapshotnum != nil) ? true : false
        let arguments = RestorefilesArguments(task: .rsyncfilelistings,
                                              config: config,
                                              remoteFile: nil,
                                              localCatalog: nil,
                                              drynrun: nil,
                                              snapshot: snapshot).getArguments()
        let command = RsyncAsync(arguments: arguments,
                                 processtermination: processtermination)
        await command.executeProcess()
    }

    func getoutput() -> [String]? {
        guard rsyncdata?.count ?? 0 > 0 else { return [] }
        let data = TrimOne(rsyncdata ?? []).trimmeddata.filter { filterstring.isEmpty ? true : $0.contains(filterstring) }
        return data
    }

    func getoutputtable() -> [RestoreFileRecord]? {
        guard rsyncdata?.count ?? 0 > 0 else { return [] }
        let data = TrimOne(rsyncdata ?? []).trimmeddata.filter { filterstring.isEmpty ? true : $0.contains(filterstring) }
        return data.map { filename in
            RestoreFileRecord(filename: filename)
        }
    }
}

extension ObserveableRestoreFilelist {
    func propogateerror(error: Error) {
        SharedReference.shared.errorobject?.propogateerror(error: error)
    }
}

// swiftlint:enable line_length
