//
//  ProcessStreamingExample.swift
//  RsyncUI
//
//  Example: How to implement streaming at the Process level
//  This is what RsyncProcess package should do internally
//  Created by GitHub Copilot on 17/12/2025.
//

import Foundation

/// Example of how to implement output streaming using Process and Pipe
/// This demonstrates the low-level implementation
class ProcessStreamingExample {
    
    /// Example of streaming output from a process
    func runProcessWithStreaming(
        command: String,
        arguments: [String],
        onLineReceived: @escaping @Sendable (String) -> Void,
        onCompletion: @escaping @Sendable ([String]) -> Void
    ) throws {
        let _onLineReceived = onLineReceived
        let _onCompletion = onCompletion
        
        let deliverLine: @Sendable (String) -> Void = { line in
            Task { @MainActor in
                _onLineReceived(line)
            }
        }
        
        let process = Process()
        process.executableURL = URL(fileURLWithPath: command)
        process.arguments = arguments
        
        let outputPipe = Pipe()
        let errorPipe = Pipe()
        
        process.standardOutput = outputPipe
        process.standardError = errorPipe
        
        actor StreamState {
            var accumulatedOutput: [String] = []
            var partialLine: String = ""

            func append(lines: [String], trailing: String) {
                accumulatedOutput.append(contentsOf: lines)
                partialLine = trailing
            }

            func flushTrailingIfNeeded() -> String? {
                guard !partialLine.isEmpty else { return nil }
                let trailing = partialLine
                accumulatedOutput.append(trailing)
                partialLine = ""
                return trailing
            }

            func snapshot() -> [String] { accumulatedOutput }

            func combineAndSplit(_ text: String) -> (lines: [String], trailing: String) {
                let combined = partialLine + text
                let parts = combined.components(separatedBy: .newlines)
                let trailing = parts.last ?? ""
                let lines = parts.dropLast().filter { !$0.isEmpty }
                return (Array(lines), trailing)
            }
        }
        let state = StreamState()
        
        // THIS IS THE KEY: Use readabilityHandler for streaming
        // Instead of waiting for process to finish and reading all data at once
        outputPipe.fileHandleForReading.readabilityHandler = { fileHandle in
            // Read available data WITHOUT blocking
            let data = fileHandle.availableData
            guard data.count > 0 else {
                // End of stream
                return
            }
            guard let text = String(data: data, encoding: .utf8) else {
                return
            }

            Task.detached(priority: nil) {
                // Safely combine with any partial line and split on the actor
                let split = await state.combineAndSplit(text)
                let completeLines = split.lines

                // Update state on the actor
                await state.append(lines: completeLines, trailing: split.trailing)

                // Stream lines to the client on main actor via sendable closure
                for line in completeLines {
                    deliverLine(line)
                }
            }
        }
        
        // Handle errors similarly
        errorPipe.fileHandleForReading.readabilityHandler = { fileHandle in
            let data = fileHandle.availableData
            if let errorText = String(data: data, encoding: .utf8), !errorText.isEmpty {
                // Handle error output
                print("Error: \(errorText)")
            }
        }
        
        // Setup termination handler
        process.terminationHandler = { _ in
            // Clean up handlers immediately on termination callback thread
            outputPipe.fileHandleForReading.readabilityHandler = nil
            errorPipe.fileHandleForReading.readabilityHandler = nil

            Task.detached(priority: nil) {
                // Flush any trailing partial line via actor
                if let trailing = await state.flushTrailingIfNeeded() {
                    deliverLine(trailing)
                }

                // Snapshot accumulated output via actor and complete on main actor
                let snapshot = await state.snapshot()
                await MainActor.run {
                    _onCompletion(snapshot)
                }
            }
        }
        
        try process.run()
    }
}

// USAGE EXAMPLE:
/*
 let streamer = ProcessStreamingExample()
 
 try streamer.runProcessWithStreaming(
     command: "/usr/bin/rsync",
     arguments: ["--version"],
     onLineReceived: { line in
         // Process each line AS IT ARRIVES
         print("Received: \(line)")
         // Update UI, parse progress, etc.
     },
     onCompletion: { allLines in
         // Final processing with complete output
         print("Complete! Total lines: \(allLines.count)")
     }
 )
 */


