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
        #if DEBUG
            debugValidateStreamingThreading()
        #endif

        return ProcessHandlers(
            processTermination: processTermination,
            fileHandler: fileHandler,
            rsyncPath: GetfullpathforRsync().rsyncpath(),
            checkLineForError: TrimOutputFromRsync().checkForRsyncError(_:),
            updateProcess: SharedReference.shared.updateprocess,
            propagateError: { error in
                SharedReference.shared.errorobject?.alert(error: error)
            },
            logger: { command, output in
                _ = await ActorLogToFile(command, output)
            },
            checkForErrorInRsyncOutput: SharedReference.shared.checkforerrorinrsyncoutput,
            rsyncVersion3: SharedReference.shared.rsyncversion3,
            environment: MyEnvironment()?.environment,
            printLine: RsyncOutputCapture.shared.makePrintLinesClosure()
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
        #if DEBUG
            debugValidateStreamingThreading()
        #endif

        return ProcessHandlers(
            processTermination: { output, hiddenID in
                processTermination(output, hiddenID)
                cleanup()
            },
            fileHandler: fileHandler,
            rsyncPath: GetfullpathforRsync().rsyncpath(),
            checkLineForError: TrimOutputFromRsync().checkForRsyncError(_:),
            updateProcess: SharedReference.shared.updateprocess,
            propagateError: { error in
                SharedReference.shared.errorobject?.alert(error: error)
            },
            logger: { command, output in
                _ = await ActorLogToFile(command, output)
            },
            checkForErrorInRsyncOutput: SharedReference.shared.checkforerrorinrsyncoutput,
            rsyncVersion3: SharedReference.shared.rsyncversion3,
            environment: MyEnvironment()?.environment,
            printLine: RsyncOutputCapture.shared.makePrintLinesClosure()
        )
    }

    #if DEBUG
        private static var threadingCheckRan = false

        /// Debug-only guard to ensure streaming callbacks can execute off the main thread
        /// (matches how RsyncProcessStreaming invokes `checkLineForError`). Runs asynchronously
        /// to avoid QoS inversion warnings from waiting on a lower-priority queue.
        private func debugValidateStreamingThreading() {
            guard Self.threadingCheckRan == false else { return }
            Self.threadingCheckRan = true

            Task.detached(priority: .userInitiated) {
                precondition(Thread.isMainThread == false, "Streaming threading check should run off the main thread")
                _ = try? TrimOutputFromRsync().checkForRsyncError("ok")
            }
        }
    #endif
}
