//
//  LogStoreServiceTests.swift
//  RsyncUITests
//

import Foundation
@testable import RsyncUI
import Testing

@Suite(.tags(.logs))
struct LogStoreServiceTests {
    @Test("Visible logs use selected configuration and preserve descending date order")
    func visibleLogsForSelectedConfiguration() {
        let first = makeLog(dateExecuted: "01 Jan 2026 09:00", resultExecuted: "older selected task")
        let second = makeLog(dateExecuted: "02 Jan 2026 11:00", resultExecuted: "newer selected task")
        let otherTask = makeLog(dateExecuted: "03 Jan 2026 08:00", resultExecuted: "other task")

        let configurations = [
            makeConfiguration(hiddenID: 7),
            makeConfiguration(hiddenID: 8)
        ]
        let store = [
            makeLogStore(hiddenID: 7, logs: [first, second]),
            makeLogStore(hiddenID: 8, logs: [otherTask])
        ]

        let logs = LogStoreService.visibleLogs(
            from: store,
            configurations: configurations,
            configurationID: configurations[0].id
        )

        #expect(logs.map(\.id) == [second.id, first.id])
    }

    @Test("Visible logs merge all tasks when no configuration is selected and apply the current filter")
    func visibleLogsAcrossAllTasksWithFilter() {
        let matchingByResult = makeLog(dateExecuted: "01 Jan 2026 09:00", resultExecuted: "keep this result")
        let filteredOut = makeLog(dateExecuted: "02 Jan 2026 09:00", resultExecuted: "ignore me")
        let matchingByDate = makeLog(dateExecuted: "03 Jan 2026 09:00", resultExecuted: "another task")
        let matchingDateFilter = matchingByDate.dateExecuted?
            .en_date_from_string()
            .long_localized_string_from_date() ?? ""

        let store = [
            makeLogStore(hiddenID: 7, logs: [matchingByResult, filteredOut]),
            makeLogStore(hiddenID: 8, logs: [matchingByDate])
        ]

        let byResult = LogStoreService.visibleLogs(
            from: store,
            configurations: nil,
            configurationID: nil,
            filterString: "keep this"
        )
        let byDate = LogStoreService.visibleLogs(
            from: store,
            configurations: nil,
            configurationID: nil,
            filterString: matchingDateFilter
        )

        #expect(byResult.map(\.id) == [matchingByResult.id])
        #expect(byDate.map(\.id) == [matchingByDate.id])
    }

    @Test("Deleting logs removes matching IDs without touching other task records")
    func deletingLogsRemovesOnlySelectedIDs() {
        let deleted = makeLog(dateExecuted: "01 Jan 2026 09:00", resultExecuted: "delete me")
        let keptSameTask = makeLog(dateExecuted: "02 Jan 2026 09:00", resultExecuted: "keep same task")
        let keptOtherTask = makeLog(dateExecuted: "03 Jan 2026 09:00", resultExecuted: "keep other task")

        let store = [
            makeLogStore(hiddenID: 7, logs: [deleted, keptSameTask]),
            makeLogStore(hiddenID: 8, logs: [keptOtherTask])
        ]

        let updatedStore = LogStoreService.deletingLogs([deleted.id], from: store)

        #expect(updatedStore?[0].logrecords?.map(\.id) == [keptSameTask.id])
        #expect(updatedStore?[1].logrecords?.map(\.id) == [keptOtherTask.id])
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

    private func makeConfiguration(hiddenID: Int) -> SynchronizeConfiguration {
        var configuration = SynchronizeConfiguration()
        configuration.hiddenID = hiddenID
        return configuration
    }
}
