//
//  SnapshotLogRecords.swift
//  RsyncSwiftUI
//
//  Created by Thomas Evensen on 23/02/2021.
//

import Foundation

struct SnapshotLogRecords: Identifiable {
    var id = UUID()
    var date: Date
    var dateExecuted: String
    var resultExecuted: String
    var period: String?
    var snapshotCatalog: String?
    var days: String?
}

extension SnapshotLogRecords: Hashable, Equatable {
    static func == (lhs: SnapshotLogRecords, rhs: SnapshotLogRecords) -> Bool {
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

final class SnapshotRecords {
    var loggrecordssnapshots: [SnapshotLogRecords]?

    private func readandsortallloggdata(_ config: SynchronizeConfiguration,
                                        _ logrecords: [LogRecords])
    {
        var data = [SnapshotLogRecords]()
        let localrecords = logrecords.filter { $0.hiddenID == config.hiddenID }
        guard localrecords.count == 1 else { return }
        for i in 0 ..< (localrecords[0].logrecords?.count ?? 0) {
            var datestring: String?
            var date: Date?
            if let stringdate = localrecords[0].logrecords?[i].dateExecuted {
                if stringdate.isEmpty == false {
                    datestring = stringdate.en_us_date_from_string().localized_string_from_date()
                    date = stringdate.en_us_date_from_string()
                }
            }
            let record =
                SnapshotLogRecords(
                    date: date ?? Date(),
                    dateExecuted: datestring ?? "",
                    resultExecuted: localrecords[0].logrecords?[i].resultExecuted ?? ""
                )
            data.append(record)
        }
        loggrecordssnapshots = data.sorted(by: \.date, using: >)
    }

    init(config: SynchronizeConfiguration,
         logrecords: [LogRecords])
    {
        if loggrecordssnapshots == nil {
            readandsortallloggdata(config, logrecords)
        }
    }
}
