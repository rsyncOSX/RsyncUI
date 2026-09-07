//
//  InterruptProcess.swift
//  RsyncUI
//

import Foundation

@MainActor
struct InterruptProcess {
    @discardableResult
    init() {
        // Capture and interrupt immediately; logging must not delay cancellation or select a newer process.
        let process = SharedReference.shared.process
        if let process, process.isRunning {
            process.interrupt()
        }
        Task {
            let string: [String] = ["Interrupted: " + Date().long_localized_string_from_date()]
            await ActorLogToFile.shared.logOutput("Interrupted", string)
        }
    }
}
