//
//  LogRecordSnapshot.swift
//  RsyncSwiftUI
//
//  Created by Thomas Evensen on 23/02/2021.
//

import Foundation

struct LogRecordSnapshot: Identifiable {
    var id = UUID()
    var date: Date
    var dateExecuted: String
    var resultExecuted: String
    var period: String?
    var snapshotCatalog: String?
    var days: String?
}

extension LogRecordSnapshot: Hashable, Equatable {
    static func == (lhs: LogRecordSnapshot, rhs: LogRecordSnapshot) -> Bool {
        lhs.dateExecuted == rhs.dateExecuted &&
            lhs.resultExecuted == rhs.resultExecuted &&
            lhs.snapshotCatalog == rhs.snapshotCatalog &&
            lhs.period == rhs.period &&
            lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(dateExecuted)
        hasher.combine(resultExecuted)
        hasher.combine(id)
        hasher.combine(snapshotCatalog)
        hasher.combine(period)
    }
}
