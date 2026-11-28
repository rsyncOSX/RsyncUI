//
//  LogfileSizeWarningTests.swift
//  RsyncUITests
//

@testable import RsyncUI
import Testing

@Suite("Logfile size warning", .tags(.logs))
struct LogfileSizeWarningTests {
    @Test("No warning at or below the limit, or when the size is unknown")
    func noWarningWithinLimit() {
        #expect(ActorLogToFile.shouldWarnAboutSize(nil, limit: 1_000_000, alreadyWarned: false) == false)
        #expect(ActorLogToFile.shouldWarnAboutSize(999_999, limit: 1_000_000, alreadyWarned: false) == false)
        #expect(ActorLogToFile.shouldWarnAboutSize(1_000_000, limit: 1_000_000, alreadyWarned: false) == false)
    }

    @Test("Warn once past the limit, not on every write")
    func warnOnce() {
        #expect(ActorLogToFile.shouldWarnAboutSize(1_000_001, limit: 1_000_000, alreadyWarned: false))
        #expect(ActorLogToFile.shouldWarnAboutSize(5_000_000, limit: 1_000_000, alreadyWarned: true) == false)
    }
}
