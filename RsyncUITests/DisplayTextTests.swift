//
//  DisplayTextTests.swift
//  RsyncUITests
//

import Foundation
@testable import RsyncUI
import Testing

@MainActor
@Suite("Displayed text")
struct DisplayTextTests {
    @Test("Singular only for one")
    func latest() {
        let hour = 3600.0
        let day = 86400.0
        #expect(hour.latest() == String(format: String(localized: "%.1f hour"), 1.0))
        #expect((hour * 1.9).latest() == String(format: String(localized: "%.1f hours"), 1.9))
        #expect(day.latest() == String(format: String(localized: "%.1f day"), 1.0))
        #expect((day * 1.9).latest() == String(format: String(localized: "%.1f days"), 1.9))
        #expect(100.0.latest() == String(format: String(localized: "%.0f mins"), 2.0))
    }

    @Test("One file in a run result")
    func runResult() {
        #expect("1 files : 1.6 MB in 2.48 seconds".displayedRunResult == "1 file : 1.6 MB in 2.48 seconds")
        #expect("(3) 1 files : 1.6 MB".displayedRunResult == "(3) 1 file : 1.6 MB")
        #expect("21 files : 1.6 MB".displayedRunResult == "21 files : 1.6 MB")
        #expect("1,1 files : 1.6 MB".displayedRunResult == "1,1 files : 1.6 MB")
    }

    @Test("A new task is never run")
    func lastRun() {
        var configuration = SynchronizeConfiguration()
        #expect(configuration.lastRun == nil)
        configuration.dateRun = ""
        #expect(configuration.lastRun == nil)
        configuration.dateRun = "25 Nov 2026 12:59"
        #expect(configuration.lastRun != nil)
    }
}
