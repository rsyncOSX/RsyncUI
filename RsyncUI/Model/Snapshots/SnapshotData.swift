//
//  SnapshotData.swift
//  RsyncSwiftUI
//
//  Created by Thomas Evensen on 23/02/2021.
//

import Foundation
import Observation

@Observable
final class SnapshotData {
    var maxnumbertodelete: Int = 0
    var remainingsnapshotstodelete: Int = 0
    // Deleteobject
    var delete: DeleteSnapshots?
    var inprogressofdelete: Bool = false
    // Show progress view when getting data
    var snapshotlist: Bool = false
    // uuids for DELETE snapshots
    var snapshotuuidsfordelete = Set<SnapshotLogRecords.ID>()
    var catalogsanddates: [Catalogsanddates] = []
    var logrecordssnapshot: [SnapshotLogRecords]?

    func setsnapshotdata(_ data: [SnapshotLogRecords]?) {
        logrecordssnapshot = data
        inprogressofdelete = false
        snapshotuuidsfordelete.removeAll()
        maxnumbertodelete = 0
        remainingsnapshotstodelete = 0
    }

    func getsnapshotdata() -> [SnapshotLogRecords]? {
        return logrecordssnapshot?.sorted(by: \.date, using: >)
    }
}

struct Catalogsanddates: Identifiable, Equatable {
    let id = UUID()
    var catalog: String
}
