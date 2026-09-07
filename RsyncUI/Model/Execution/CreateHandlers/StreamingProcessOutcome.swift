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

    /// A completed process must not clear a newer process started by its callback.
    func updatedProcess(_ incoming: Process?, current: Process?) -> Process? {
        if let incoming {
            process = incoming
            return incoming
        }
        return current === process ? nil : current
    }

    var outcome: StreamingProcessOutcome {
        guard let process, !process.isRunning else { return .failure }
        return .resolve(exitStatus: process.terminationStatus,
                        signalled: process.terminationReason == .uncaughtSignal,
                        hadError: hadError)
    }
}
