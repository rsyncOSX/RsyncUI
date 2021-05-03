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
    private var logrecordssnapshot: [Logrecordsschedules]?
    var state: Snapshotdatastat = .start
    // Remote num of snapshot catalogs
    // Number of saved logrecords on local storage
    var numremotecatalogs: Int = 0
    var numlocallogrecords: Int = 0
    var uuidsLog: Set<UUID>?

    func setsnapshotdata(_ data: [Logrecordsschedules]?) {
        logrecordssnapshot = data
        objectWillChange.send()
    }

    func getsnapshotdata() -> [Logrecordsschedules]? {
        return logrecordssnapshot?.sorted(by: \.date, using: >)
    }
}
