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
    @Published var remainingsnapshotstodelete: Int = 0
    // Deleteobject
    @Published var delete: DeleteSnapshots?
    @Published var inprogressofdelete: Bool = false
    // Show progress view when getting data
    @Published var snapshotlist: Bool = false
    // uuids for DELETE snapshots
    @Published var snapshotuuidsfordelete = Set<LogrecordSnapshot.ID>()
    @Published var catalogsanddates: [Catalogsanddates] = []
    var logrecordssnapshot: [LogrecordSnapshot]?
    var state: Snapshotdatastat = .start

    func setsnapshotdata(_ data: [LogrecordSnapshot]?) {
        logrecordssnapshot = data
        inprogressofdelete = false
        snapshotuuidsfordelete.removeAll()
        maxnumbertodelete = 0
        remainingsnapshotstodelete = 0
        objectWillChange.send()
    }

    func getsnapshotdata() -> [LogrecordSnapshot]? {
        return logrecordssnapshot?.sorted(by: \.date, using: >)
    }
}

struct Catalogsanddates: Identifiable, Equatable {
    let id = UUID()
    var catalog: String
}
