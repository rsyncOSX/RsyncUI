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
    // Show progress view when getting data
    @Published var snapshotlist: Bool = false
    // uuids for DELETE snapshots
    @Published var snapshotuuidsfordelete = Set<Logrecordsschedules.ID>()

    var logrecordssnapshot: [Logrecordsschedules]?
    var state: Snapshotdatastat = .start

    func setsnapshotdata(_ data: [Logrecordsschedules]?) {
        logrecordssnapshot = data
        inprogressofdelete = false
        maxnumbertodelete = snapshotuuidsfordelete.count
        progressindelete = 0
        objectWillChange.send()
    }

    func getsnapshotdata() -> [Logrecordsschedules]? {
        return logrecordssnapshot?.sorted(by: \.date, using: >)
    }
}
