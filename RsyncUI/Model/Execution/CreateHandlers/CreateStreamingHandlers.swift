//
//  CreateStreamingHandlers.swift
//  RsyncUI
//
//  Created by GitHub Copilot on 17/12/2025.
//

import Foundation
import RsyncProcess

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
        processTermination: @escaping ([String]?, Int?) -> Void,
        streamingHandler: StreamingOutputHandler? = nil
    ) -> ProcessHandlers {
        
        // Create a print line closure that feeds the streaming handler
        let printLineClosure: (String) -> Void = { line in
            // Feed to streaming handler if provided
            streamingHandler?.handleLine(line)
            
            // Also send to RsyncOutputCapture for real-time view
            RsyncOutputCapture.shared.makePrintLinesClosure()(line)
        }
        
        // Wrap the original processTermination to provide streaming output
        let wrappedTermination: ([String]?, Int?) -> Void = { output, hiddenID in
            // If we have a streaming handler, use its accumulated output
            // This gives us the most recent lines without memory overflow
            let finalOutput = streamingHandler?.getAllLines() ?? output
            processTermination(finalOutput, hiddenID)
        }
        
        return ProcessHandlers(
            processTermination: wrappedTermination,
            fileHandler: fileHandler,
            rsyncPath: GetfullpathforRsync().rsyncpath,
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
            printLine: printLineClosure
        )
    }
}
