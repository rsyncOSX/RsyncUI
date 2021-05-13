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

    var logrecordssnapshot: [Logrecordsschedules]?
    var state: Snapshotdatastat = .start
    // uuids from ALL the logrecords
    var uuidsfromlogrecords: Set<UUID>?
    // uuids for DELETE snapshots
    var uuidsfordelete: Set<UUID>?

    func setsnapshotdata(_ data: [Logrecordsschedules]?) {
        logrecordssnapshot = data
        uuidsfordelete = nil
        uuidsfromlogrecords = nil
        inprogressofdelete = false
        maxnumbertodelete = 0
        progressindelete = 0
        objectWillChange.send()
    }

    func getsnapshotdata() -> [Logrecordsschedules]? {
        return logrecordssnapshot?.sorted(by: \.date, using: >)
    }
}
