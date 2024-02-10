//
//  SnapshotLogRecords.swift
//  RsyncSwiftUI
//
//  Created by Thomas Evensen on 23/02/2021.
//
// swiftlint:disable line_length

import Foundation

struct SnapshotLogRecords: Identifiable {
    var id = UUID()
    var hiddenID: Int
    var localCatalog: String
    var remoteCatalog: String
    var offsiteServer: String
    var task: String
    var backupID: String
    var dateExecuted: String
    var date: Date
    var resultExecuted: String
    // Snapshots
    var period: String?
    var days: String?
    var snapshotCatalog: String?
    var seconds: Int = 0
}

final class SnapshotRecords {
    var loggrecordssnapshots: [SnapshotLogRecords]?
    private var localehiddenID: Int?

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
                    hiddenID: config.hiddenID,
                    localCatalog: config.localCatalog,
                    remoteCatalog: config.offsiteCatalog,
                    offsiteServer: config.offsiteServer,
                    task: config.task,
                    backupID: config.backupID,
                    dateExecuted: datestring ?? "",
                    date: date ?? Date(),
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

extension SnapshotLogRecords: Hashable, Equatable {
    static func == (lhs: SnapshotLogRecords, rhs: SnapshotLogRecords) -> Bool {
        return lhs.dateExecuted == rhs.dateExecuted &&
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

// swiftlint:enable line_length
