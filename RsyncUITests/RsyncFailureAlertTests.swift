import RsyncProcessStreaming
@testable import RsyncUI
import Testing

struct RsyncFailureAlertTests {
    @Test func largeMultilineChunk() {
        let lines = (0 ..< 100_000).map { "Line \($0)" } + ["rsync error: failed"]
        let alert = RsyncFailureAlert(exitCode: 23, chunks: [lines.joined(separator: "\n")])
        #expect(alert.lines == Array(lines.suffix(10)))
        #expect(alert.errorDescription?.hasPrefix("rsync exited with code 23.") == true)
    }

    @Test func preservesEarlierErrorAcrossChunks() {
        let tail = (0 ..< 30).map { "Line \($0)" }
        let alert = RsyncFailureAlert(exitCode: 12, chunks: ["first error\nlatest ERROR", tail.joined(separator: "\r\n")])
        #expect(alert.lines == ["latest ERROR"] + tail.suffix(9))
    }

    @Test func shortAndEmptyOutput() {
        #expect(RsyncFailureAlert(exitCode: 1, chunks: []).lines.isEmpty)
        #expect(RsyncFailureAlert(exitCode: 1, chunks: ["error\ndetail"]).lines == ["error", "detail"])
    }

    @MainActor @Test func handlerPresentsBoundedFailure() throws {
        let previous = SharedReference.shared.errorobject
        defer { SharedReference.shared.errorobject = previous }
        let alerts = AlertError()
        SharedReference.shared.errorobject = alerts
        let handlers = CreateStreamingHandlers().createResultHandlers(fileHandler: { _ in }, processTermination: { _, _, _ in })
        let lines = (0 ..< 100).map { "Line \($0)" } + ["rsync error: failed"]
        handlers.propagateError(RsyncProcessError.processFailed(exitCode: 23, errors: [lines.joined(separator: "\n")]))
        let failure = try #require(alerts.activeError as? RsyncFailureAlert)
        #expect(failure.exitCode == 23)
        #expect(failure.lines == Array(lines.suffix(10)))
    }

    @MainActor @Test(arguments: [false, true])
    func settingControlsBothChecks(_ enabled: Bool) {
        let previous = SharedReference.shared.checkforerrorinrsyncoutput
        defer { SharedReference.shared.checkforerrorinrsyncoutput = previous }
        SharedReference.shared.checkforerrorinrsyncoutput = enabled
        let handlers = CreateStreamingHandlers().createResultHandlers(fileHandler: { _ in }, processTermination: { _, _, _ in })
        #expect(handlers.checkForErrorInRsyncOutput == enabled)
        if enabled {
            #expect(throws: Rsyncerror.self) { try handlers.checkLineForError("rsync error: failed") }
        } else {
            #expect(throws: Never.self) { try handlers.checkLineForError("rsync error: failed") }
        }
    }
}
