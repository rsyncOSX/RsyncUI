//
//  InterruptProcess.swift
//  RsyncOSX
//
//  Created by Thomas Evensen on 18/06/2020.
//  Copyright © 2020 Thomas Evensen. All rights reserved.
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
