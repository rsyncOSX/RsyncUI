//
//  TagSnapshotsTests.swift
//  RsyncUITests
//

import Foundation
@testable import RsyncUI
import Testing

@Suite("Snapshot tagging around New Year")
struct TagSnapshotsTests {
    private func date(_ year: Int, _ month: Int, _ day: Int) throws -> Date {
        try #require(Calendar.current.date(from: DateComponents(year: year, month: month, day: day, hour: 12)))
    }

    private func record(_ date: Date) -> LogRecordSnapshot {
        LogRecordSnapshot(idlogrecord: UUID(),
                          dateExecuted: date.localized_string_from_date(),
                          resultExecuted: "(1) 10 files : 1.00 MB in 1.00 seconds")
    }

    @Test("A week spanning New Year is one week")
    func weekAcrossNewYear() throws {
        #expect(TagSnapshots.isSameWeek(try date(2026, 12, 29), try date(2027, 1, 2)))
        #expect(TagSnapshots.isSameWeek(try date(2026, 12, 15), try date(2027, 1, 2)) == false)
        #expect(TagSnapshots.isSameWeek(try date(2025, 12, 30), try date(2026, 12, 29)) == false)
    }

    @Test("December is the previous month in January")
    func previousMonthInJanuary() throws {
        #expect(TagSnapshots.isPreviousMonth(try date(2026, 12, 10), try date(2027, 1, 2)))
        #expect(TagSnapshots.isPreviousMonth(try date(2026, 11, 10), try date(2027, 1, 2)) == false)
        #expect(TagSnapshots.isPreviousMonth(try date(2026, 10, 10), try date(2026, 11, 2)))
    }

    @Test("A snapshot from late December is kept as this week in early January")
    func lateDecemberSnapshotIsKept() throws {
        let now = try date(2027, 1, 2)
        // The last element is never tagged, so an older record goes last.
        let data = [record(try date(2026, 12, 29)), record(try date(2026, 6, 1))]
        let tagged = TagSnapshots(plan: 1, snapdayoffweek: "sunday", data: data, now: now)
        #expect(tagged.logrecordssnapshot?[0].period == "Keep this week")
    }
}
