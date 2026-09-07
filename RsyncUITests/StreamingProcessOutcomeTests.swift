import Foundation
import RsyncProcessStreaming
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

    @MainActor @Test("Previous process cleanup preserves the next batch process")
    func processOwnership() {
        let firstOwner = StreamingProcessCompletion()
        let secondOwner = StreamingProcessCompletion()
        let first = Process()
        let second = Process()
        var current = firstOwner.updatedProcess(first, current: nil)
        current = secondOwner.updatedProcess(second, current: current)
        current = firstOwner.updatedProcess(nil, current: current)
        #expect(current === second)
        current = secondOwner.updatedProcess(nil, current: current)
        #expect(current == nil)
    }

    @MainActor @Test("Streaming handlers do not clear another handler's process")
    func handlerOwnership() {
        let previous = SharedReference.shared.process
        defer { SharedReference.shared.process = previous }
        let first = CreateStreamingHandlers().createResultHandlers(fileHandler: { _ in }, processTermination: { _, _, _ in })
        let second = CreateStreamingHandlers().createResultHandlers(fileHandler: { _ in }, processTermination: { _, _, _ in })
        let firstProcess = Process()
        let secondProcess = Process()
        first.updateProcess(firstProcess)
        second.updateProcess(secondProcess)
        first.updateProcess(nil)
        #expect(SharedReference.shared.process === secondProcess)
        second.updateProcess(nil)
        #expect(SharedReference.shared.process == nil)
    }
}
