//
//  CreateStreamingHandlers.swift
//  RsyncUI
//
//  Created by GitHub Copilot on 17/12/2025.
//

import Foundation
import RsyncProcessStreaming

@MainActor
struct CreateStreamingHandlers {
    /// Create handlers with streaming output support
    /// - Parameters:
    ///   - fileHandler: Progress callback (file count)
    ///   - processTermination: Called when process completes (receives final output)
    ///   - streamingHandler: Optional handler for line-by-line processing
    /// - Returns: ProcessHandlers configured for streaming
    func createHandlers(
        fileHandler: @escaping (Int) -> Void,
        processTermination: @escaping ([String]?, Int?) -> Void
    ) -> ProcessHandlers {
        makeHandlers(fileHandler: fileHandler, reportUnreportedFailure: false) { output, hiddenID, _ in
            processTermination(output, hiddenID)
        }
    }

    /// Completion includes the actual process result, independent of output parsing.
    /// A failed exit that nothing else reported is shown to the user with its exit code.
    func createResultHandlers(
        fileHandler: @escaping (Int) -> Void,
        processTermination: @escaping ([String]?, Int?, StreamingProcessOutcome) -> Void
    ) -> ProcessHandlers {
        makeHandlers(fileHandler: fileHandler, reportUnreportedFailure: true, processTermination: processTermination)
    }

    /// With "Check for error in output" off, RsyncProcessStreaming does not report a
    /// non-zero exit. The outcome is still a failure, so say so instead of stopping silently.
    static func unreportedFailureAlert(outcome: StreamingProcessOutcome,
                                       hadError: Bool,
                                       exitStatus: Int32?) -> RsyncFailureAlert? {
        guard outcome == .failure, hadError == false, let exitStatus, exitStatus != 0 else { return nil }
        return RsyncFailureAlert(exitCode: exitStatus, chunks: [])
    }

    private func makeHandlers(
        fileHandler: @escaping (Int) -> Void,
        reportUnreportedFailure: Bool,
        processTermination: @escaping ([String]?, Int?, StreamingProcessOutcome) -> Void
    ) -> ProcessHandlers {
        #if DEBUG
            debugValidateStreamingThreading()
        #endif
        let completion = StreamingProcessCompletion()
        let checkForErrors = SharedReference.shared.checkforerrorinrsyncoutput
        return ProcessHandlers(
            processTermination: { output, hiddenID in
                let outcome = completion.outcome
                // terminationStatus may only be read once the process has exited.
                let exitStatus = completion.process.flatMap { $0.isRunning ? nil : $0.terminationStatus }
                if reportUnreportedFailure,
                   let alert = Self.unreportedFailureAlert(outcome: outcome,
                                                           hadError: completion.hadError,
                                                           exitStatus: exitStatus) {
                    completion.hadError = true
                    SharedReference.shared.errorobject?.alert(error: alert)
                }
                processTermination(output, hiddenID, outcome)
            },
            fileHandler: fileHandler,
            rsyncPath: GetfullpathforRsync().rsyncpath(),
            checkLineForError: { line in
                guard checkForErrors else { return }
                try TrimOutputFromRsync().checkForRsyncError(line)
            },
            updateProcess: { process in
                let current = SharedReference.shared.process
                SharedReference.shared.updateprocess(completion.updatedProcess(process, current: current))
            },
            propagateError: { error in
                completion.hadError = true
                if let error = error as? RsyncProcessError, case .processCancelled = error {
                    return
                }
                if let processError = error as? RsyncProcessError,
                   case let .processFailed(exitCode, errors) = processError {
                    SharedReference.shared.errorobject?.alert(
                        error: RsyncFailureAlert(exitCode: exitCode, chunks: errors)
                    )
                } else {
                    SharedReference.shared.errorobject?.alert(error: error)
                }
            },
            checkForErrorInRsyncOutput: checkForErrors,
            environment: MyEnvironment()?.environment
        )
    }

    /// Create handlers that automatically perform cleanup after termination.
    /// Use this to avoid retain cycles by ensuring long-lived references are released
    /// right after the termination callback completes.
    /// - Parameters:
    ///   - fileHandler: Progress callback (file count)
    ///   - processTermination: Called when process completes (receives final output)
    ///   - cleanup: Invoked immediately after `processTermination` to release references
    /// - Returns: ProcessHandlers configured for streaming with enforced cleanup
    func createHandlersWithCleanup(
        fileHandler: @escaping (Int) -> Void,
        processTermination: @escaping ([String]?, Int?) -> Void,
        cleanup: @escaping () -> Void
    ) -> ProcessHandlers {
        createHandlers(fileHandler: fileHandler) { output, hiddenID in
            processTermination(output, hiddenID)
            cleanup()
        }
    }

    #if DEBUG
        private static var threadingCheckRan = false

        /// Debug-only guard to ensure streaming callbacks can execute off the main thread
        /// (matches how RsyncProcessStreaming invokes `checkLineForError`). Runs asynchronously
        /// to avoid QoS inversion warnings from waiting on a lower-priority queue.
        private func debugValidateStreamingThreading() {
            guard Self.threadingCheckRan == false else { return }
            Self.threadingCheckRan = true

            // Task.detached is required here to guarantee this runs off the main actor,
            // regardless of caller isolation — this validates streaming callbacks are not
            // invoked on the main thread.
            Task.detached(priority: .userInitiated) {
                precondition(Thread.isMainThread == false, "Streaming threading check should run off the main thread")
                _ = try? TrimOutputFromRsync().checkForRsyncError("ok")
            }
        }
    #endif
}
