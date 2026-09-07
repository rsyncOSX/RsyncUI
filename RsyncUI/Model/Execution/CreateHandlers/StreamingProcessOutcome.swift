import Foundation

/// Exit status is authoritative even when optional output diagnostics are disabled.
enum StreamingProcessOutcome: Equatable {
    case success
    case failure
    case cancelled

    static func resolve(exitStatus: Int32?, signalled: Bool, hadError: Bool) -> Self {
        if signalled || exitStatus == 20 {
            return .cancelled
        }
        return exitStatus == 0 && !hadError ? .success : .failure
    }
}

@MainActor
final class StreamingProcessCompletion {
    var process: Process?
    var hadError = false

    var outcome: StreamingProcessOutcome {
        guard let process, !process.isRunning else { return .failure }
        return .resolve(exitStatus: process.terminationStatus,
                        signalled: process.terminationReason == .uncaughtSignal,
                        hadError: hadError)
    }
}
