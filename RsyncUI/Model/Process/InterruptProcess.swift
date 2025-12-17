//
//  InterruptProcess.swift
//  RsyncUI
//

import Foundation

@MainActor
struct InterruptProcess {
    @discardableResult
    init() {
        Task {
            let string: [String] = ["Interrupted: " + Date().long_localized_string_from_date()]
            await ActorLogToFile("Interrupted", string)
            SharedReference.shared.process?.interrupt()
            SharedReference.shared.process = nil
        }
    }
}
