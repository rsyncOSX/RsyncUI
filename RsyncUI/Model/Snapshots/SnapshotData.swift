//
//  SnapshotData.swift
//  RsyncSwiftUI
//
//  Created by Thomas Evensen on 23/02/2021.
//

import Foundation

enum Snapshotdatastat {
    case start
    case getdata
    case gotit
}

final class SnapshotData: ObservableObject {
    @Published var maxnumbertodelete: Int = 0
    @Published var progressindelete: Int = 0
    // Deleteobject
    @Published var delete: DeleteSnapshots?
    @Published var inprogressofdelete: Bool = false

    private var logrecordssnapshot: [Logrecordsschedules]?
    var state: Snapshotdatastat = .start
    // Remote num of snapshot catalogs
    // Number of saved logrecords on local storage
    var numremotecatalogs: Int = 0
    var numlocallogrecords: Int = 0
    var uuidsLog: Set<UUID>?
    // selected uuids for delete
    var uuidstodelete: Set<UUID>?

    func setsnapshotdata(_ data: [Logrecordsschedules]?) {
        logrecordssnapshot = data
        numremotecatalogs = 0
        numlocallogrecords = 0
        uuidstodelete = nil
        uuidsLog = nil
        inprogressofdelete = false
        maxnumbertodelete = 0
        progressindelete = 0
        objectWillChange.send()
    }

    func getsnapshotdata() -> [Logrecordsschedules]? {
        return logrecordssnapshot?.sorted(by: \.date, using: >)
    }
}
