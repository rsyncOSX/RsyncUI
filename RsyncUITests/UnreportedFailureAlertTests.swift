//
//  UnreportedFailureAlertTests.swift
//  RsyncUITests
//

@testable import RsyncUI
import Testing

@MainActor
@Suite("Failed exit that nothing reported")
struct UnreportedFailureAlertTests {
    @Test("A failed exit nobody reported shows its exit code", arguments: [Int32(1), 12, 23, 24, 255])
    func unreportedFailureIsShown(_ status: Int32) throws {
        let alert = try #require(CreateStreamingHandlers.unreportedFailureAlert(outcome: .failure,
                                                                              hadError: false,
                                                                              exitStatus: status))
        #expect(alert.exitCode == status)
        #expect(alert.errorDescription == "rsync exited with code \(status).")
    }

    @Test("No second alert when the failure was already reported")
    func reportedFailureIsNotRepeated() {
        #expect(CreateStreamingHandlers.unreportedFailureAlert(outcome: .failure, hadError: true, exitStatus: 23) == nil)
    }

    @Test("No alert for success, cancellation or an unknown exit")
    func noAlertOtherwise() {
        #expect(CreateStreamingHandlers.unreportedFailureAlert(outcome: .success, hadError: false, exitStatus: 0) == nil)
        #expect(CreateStreamingHandlers.unreportedFailureAlert(outcome: .cancelled, hadError: false, exitStatus: 20) == nil)
        #expect(CreateStreamingHandlers.unreportedFailureAlert(outcome: .failure, hadError: false, exitStatus: nil) == nil)
    }
}
