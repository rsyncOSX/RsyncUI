//
//  StreamingOutputHandler.swift
//  RsyncUI
//
//  Created by GitHub Copilot on 17/12/2025.
//

import Foundation
import OSLog

/// Handles rsync output line-by-line as it arrives, instead of buffering everything
@MainActor
final class StreamingOutputHandler {
    private var accumulatedLines: [String] = []
    private let maxBufferSize: Int
    private let onLineReceived: ((String) -> Void)?
    private let onBatchReceived: (([String]) -> Void)?
    
    /// Initialize streaming output handler
    /// - Parameters:
    ///   - maxBufferSize: Maximum number of lines to keep in memory (default: 100)
    ///   - onLineReceived: Callback for each line as it arrives (optional)
    ///   - onBatchReceived: Callback for batch updates (optional)
    init(
        maxBufferSize: Int = 100,
        onLineReceived: ((String) -> Void)? = nil,
        onBatchReceived: (([String]) -> Void)? = nil
    ) {
        self.maxBufferSize = maxBufferSize
        self.onLineReceived = onLineReceived
        self.onBatchReceived = onBatchReceived
    }
    
    /// Process a single line of output as it arrives
    func handleLine(_ line: String) {
        Logger.process.debugThreadOnly("StreamingOutputHandler: received line")
        
        // Callback for immediate processing
        onLineReceived?(line)
        
        // Add to buffer
        accumulatedLines.append(line)
        
        // Implement rolling buffer to prevent memory issues
        if accumulatedLines.count > maxBufferSize {
            // Keep only the last N lines
            accumulatedLines.removeFirst(accumulatedLines.count - maxBufferSize)
        }
        
        // Optional: batch updates every N lines
        if accumulatedLines.count % 10 == 0 {
            onBatchReceived?(accumulatedLines)
        }
    }
    
    /// Get all accumulated lines
    func getAllLines() -> [String] {
        accumulatedLines
    }
    
    /// Get only the most recent N lines
    func getRecentLines(_ count: Int) -> [String] {
        guard accumulatedLines.count > count else {
            return accumulatedLines
        }
        return Array(accumulatedLines.suffix(count))
    }
    
    /// Clear the buffer
    func clear() {
        accumulatedLines.removeAll()
    }
    
    /// Get summary statistics (useful for rsync output)
    func getSummaryLines() -> [String] {
        // Rsync summary is typically in the last 20 lines
        getRecentLines(20)
    }
}
