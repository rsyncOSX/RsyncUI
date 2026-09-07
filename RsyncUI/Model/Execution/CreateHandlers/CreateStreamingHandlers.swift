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
        createResultHandlers(fileHandler: fileHandler) { output, hiddenID, _ in
            processTermination(output, hiddenID)
        }
    }

    /// Completion includes the actual process result, independent of output parsing.
    func createResultHandlers(
        fileHandler: @escaping (Int) -> Void,
        processTermination: @escaping ([String]?, Int?, StreamingProcessOutcome) -> Void
    ) -> ProcessHandlers {
        #if DEBUG
            debugValidateStreamingThreading()
        #endif
        let completion = StreamingProcessCompletion()
        return ProcessHandlers(
            processTermination: { output, hiddenID in
                processTermination(output, hiddenID, completion.outcome)
            },
            fileHandler: fileHandler,
            rsyncPath: GetfullpathforRsync().rsyncpath(),
            checkLineForError: TrimOutputFromRsync().checkForRsyncError(_:),
            updateProcess: { process in
                let current = SharedReference.shared.process
                SharedReference.shared.updateprocess(completion.updatedProcess(process, current: current))
            },
            propagateError: { error in
                completion.hadError = true
                if let error = error as? RsyncProcessError, case .processCancelled = error {
                    return
                }
                SharedReference.shared.errorobject?.alert(error: error)
            },
            checkForErrorInRsyncOutput: true,
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
