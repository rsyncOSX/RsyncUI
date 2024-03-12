//
//  AlertError.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 20/12/2023.
//

import Foundation
import Observation
import SwiftUI

@Observable
final class AlertError: @unchecked Sendable {
    private(set) var activeError: Error?

    func alert(error: Error) {
        DispatchQueue.main.async {
            self.activeError = error
        }
    }

    var presentalert: Binding<Bool> {
        return Binding<Bool>(
            get: { self.activeError != nil },
            set: { value in
                guard !value else { return }
                self.activeError = nil
            }
        )
    }
}

extension Alert {
    init(localizedError: Error) {
        self = Alert(nsError: localizedError as NSError)
    }

    init(nsError: NSError) {
        let message: Text? = {
            let message = [nsError.localizedFailureReason,
                           nsError.localizedRecoverySuggestion]
                .compactMap { $0 }.joined(separator: "\n\n")
            return message.isEmpty ? nil : Text(message)
        }()
        self = Alert(title: Text(nsError.localizedDescription),
                     message: message,
                     dismissButton: .default(Text("OK")))
    }
}
