//
//  EstimateWithStreaming.swift
//  RsyncUI
//
//  Example: How to use streaming in Estimate
//  Created by GitHub Copilot on 17/12/2025.
//

import Foundation
import OSLog
import ParseRsyncOutput
import RsyncProcess

/// Example of how to refactor Estimate.swift to use streaming
@MainActor
final class EstimateWithStreaming {
    private var localconfigurations: [SynchronizeConfiguration]
    private var structprofile: String?
    weak var localprogressdetails: ProgressDetails?
    var stackoftasks: [Int]?
    
    // NEW: Streaming handler
    private var streamingHandler: StreamingOutputHandler?
    
    private func startEstimation() {
        guard (stackoftasks?.count ?? 0) > 0 else { return }
        
        // Create streaming handler with callbacks
        streamingHandler = StreamingOutputHandler(
            maxBufferSize: 100,  // Keep only last 100 lines in memory
            onLineReceived: { [weak self] line in
                // Process each line as it arrives
                self?.handleStreamingLine(line)
            },
            onBatchReceived: { [weak self] lines in
                // Optional: Update UI every 10 lines
                self?.updateProgressWithBatch(lines)
            }
        )
        
        // Create handlers with streaming support
        let handlers = CreateStreamingHandlers().createHandlers(
            fileHandler: { _ in },
            processTermination: processTermination,
            streamingHandler: streamingHandler
        )
        
        // Rest of your code...
        guard let localhiddenID = stackoftasks?.removeFirst(),
              let config = getConfig(localhiddenID),
              let arguments = ArgumentsSynchronize(config: config)
                  .argumentsSynchronize(dryRun: true, forDisplay: false)
        else { return }
        
        guard SharedReference.shared.norsync == false else { return }
        guard config.task != SharedReference.shared.halted else { return }
        
        let process = RsyncProcess(
            arguments: arguments,
            hiddenID: config.hiddenID,
            handlers: handlers,
            useFileHandler: false
        )
        
        do {
            try process.executeProcess()
        } catch {
            SharedReference.shared.errorobject?.alert(error: error)
        }
    }
    
    // NEW: Handle each line as it arrives
    private func handleStreamingLine(_ line: String) {
        Logger.process.debugThreadOnly("EstimateWithStreaming: streaming line: \(line)")
        
        // You can parse progress info from the line in real-time
        // For example, rsync outputs transfer progress like:
        // "sending incremental file list"
        // "          1,234 100%  123.45kB/s    0:00:01"
        
        // Extract file count or progress percentage if needed
        // Update your progress view in real-time
    }
    
    // NEW: Handle batch updates
    private func updateProgressWithBatch(_ lines: [String]) {
        // Update UI with latest batch
        // This is less frequent than line-by-line
    }
    
    private func processTermination(stringoutputfromrsync: [String]?, _ hiddenID: Int?) {
        // Now you receive ONLY the last 100 lines (if using streaming handler)
        // instead of potentially thousands of lines
        
        var adjustedoutputfromrsync = false
        var suboutput: [String]?
        
        if (stringoutputfromrsync?.count ?? 0) > 20, let stringoutputfromrsync {
            adjustedoutputfromrsync = true
            suboutput = PrepareOutputFromRsync().prepareOutputFromRsync(stringoutputfromrsync)
        }
        
        let outputToProcess = adjustedoutputfromrsync ? suboutput : stringoutputfromrsync
        
        let resolvedHiddenID = hiddenID ?? -1
        var record = RemoteDataNumbers(
            stringoutputfromrsync: outputToProcess,
            config: getConfig(resolvedHiddenID)
        )
        
        Task {
            record.outputfromrsync = 
                await ActorCreateOutputforView().createOutputForView(stringoutputfromrsync)
            localprogressdetails?.appendRecordEstimatedList(record)
            
            if record.datatosynchronize {
                if let config = getConfig(resolvedHiddenID) {
                    localprogressdetails?.appendUUIDWithDataToSynchronize(config.id)
                }
            }
            
            // Continue with next task
            startEstimation()
        }
    }
    
    private func getConfig(_ hiddenID: Int) -> SynchronizeConfiguration? {
        if let index = localconfigurations.firstIndex(where: { $0.hiddenID == hiddenID }) {
            return localconfigurations[index]
        }
        return nil
    }
    
    init(profile: String?,
         configurations: [SynchronizeConfiguration],
         selecteduuids: Set<UUID>,
         progressdetails: ProgressDetails?) {
        self.structprofile = profile
        self.localconfigurations = configurations
        self.localprogressdetails = progressdetails
        // Initialize...
    }
}
