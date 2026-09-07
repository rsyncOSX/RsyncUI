import Foundation
@testable import RsyncUI
import Testing

struct StreamingProcessOutcomeTests {
    @Test(arguments: [Int32(1), 12, 23, 24, 255])
    func failuresNeverSucceed(_ status: Int32) {
        #expect(StreamingProcessOutcome.resolve(exitStatus: status, signalled: false, hadError: false) == .failure)
    }

    @Test func successfulExit() {
        #expect(StreamingProcessOutcome.resolve(exitStatus: 0, signalled: false, hadError: false) == .success)
        #expect(StreamingProcessOutcome.resolve(exitStatus: 0, signalled: false, hadError: true) == .failure)
        #expect(StreamingProcessOutcome.resolve(exitStatus: nil, signalled: false, hadError: false) == .failure)
    }

    @Test func cancellationNeverSucceeds() {
        #expect(StreamingProcessOutcome.resolve(exitStatus: 20, signalled: false, hadError: false) == .cancelled)
        #expect(StreamingProcessOutcome.resolve(exitStatus: 15, signalled: true, hadError: false) == .cancelled)
    }

    @MainActor @Test("Read the actual exit status from the completed process")
    func actualFailedProcess() throws {
        let completion = StreamingProcessCompletion()
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/sh")
        process.arguments = ["-c", "exit 23"]
        completion.process = process
        try process.run()
        process.waitUntilExit()
        #expect(completion.outcome == .failure)
    }
}
