//
//  LogChartReducerTests.swift
//  RsyncUITests
//

import Foundation
@testable import RsyncUI
import Testing

@Suite(.tags(.logs))
struct LogChartReducerTests {
    @Test("Files chart keeps the max record per day for one task")
    func maxPerDayByFilesForSelectedTask() {
        let store = [
            makeLogStore(
                hiddenID: 7,
                logs: [
                    makeLog(dateExecuted: "01 Jan 2026 10:00", resultExecuted: "10 files : 1.50 MB in 3.0 seconds"),
                    makeLog(dateExecuted: "01 Jan 2026 12:00", resultExecuted: "18 files : 0.80 MB in 2.0 seconds"),
                    makeLog(dateExecuted: "02 Jan 2026 09:00", resultExecuted: "3 snapshots : 12 files : 5.50 MB in 9.0 seconds"),
                    makeLog(dateExecuted: "03 Jan 2026 09:00", resultExecuted: "not a parsable result")
                ]
            ),
            makeLogStore(
                hiddenID: 8,
                logs: [
                    makeLog(dateExecuted: "02 Jan 2026 14:00", resultExecuted: "99 files : 50.0 MB in 1.0 seconds")
                ]
            )
        ]

        let entries = LogChartReducer.chartEntries(
            from: store,
            hiddenID: 7,
            metric: .files,
            limit: .maxPerDay
        )

        #expect(entries.count == 2)
        #expect(entries.map(\.files) == [12, 18])
        #expect(entries.allSatisfy { $0.dateExecutedDay != "03 Jan 2026" })
    }

    @Test("Transferred-size chart keeps top N after daily reduction across all tasks")
    func topNPerDayByTransferredSizeAcrossAllTasks() {
        let store = [
            makeLogStore(
                hiddenID: 7,
                logs: [
                    makeLog(dateExecuted: "01 Jan 2026 08:00", resultExecuted: "20 files : 8.00 MB in 3.0 seconds"),
                    makeLog(dateExecuted: "01 Jan 2026 18:00", resultExecuted: "21 files : 15.00 MB in 4.0 seconds"),
                    makeLog(dateExecuted: "02 Jan 2026 09:00", resultExecuted: "25 files : 12.00 MB in 2.0 seconds")
                ]
            ),
            makeLogStore(
                hiddenID: 8,
                logs: [
                    makeLog(dateExecuted: "03 Jan 2026 07:00", resultExecuted: "2 snapshots : 11 files : 9.00 MB in 8.0 seconds"),
                    makeLog(dateExecuted: "04 Jan 2026 10:00", resultExecuted: "9 files : 21.00 MB in 1.0 seconds")
                ]
            )
        ]

        let entries = LogChartReducer.chartEntries(
            from: store,
            hiddenID: -1,
            metric: .transferredMB,
            limit: .topNPerDay(2)
        )

        #expect(entries.count == 2)
        #expect(entries.map(\.transferredMB) == [21.0, 15.0])
        #expect(entries.map(\.dateExecutedDay) == ["04 Jan 2026", "01 Jan 2026"])
    }

    private func makeLog(dateExecuted: String, resultExecuted: String) -> Log {
        Log(dateExecuted: dateExecuted, resultExecuted: resultExecuted)
    }

    private func makeLogStore(hiddenID: Int, logs: [Log]) -> LogRecords {
        var record = LogRecords()
        record.hiddenID = hiddenID
        record.dateStart = "01 Jan 2026 00:00"
        record.logrecords = logs
        return record
    }
}

private extension LogEntry {
    var dateExecutedDay: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en")
        formatter.dateFormat = "dd MMM yyyy"
        return formatter.string(from: date)
    }
}
