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
            printLine: { line in print("line: \(line)") }
        )
    }
}
