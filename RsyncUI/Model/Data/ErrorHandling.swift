//
//  ErrorHandling.swift
//  RsyncSwiftUI
//
//  Created by Thomas Evensen on 01/02/2021.
//

import Foundation
import Observation
import SwiftUI

@Observable
final class ErrorHandling {
    private(set) var activeError: Error?

    func alerterror(error: Error) {
        DispatchQueue.main.async {
            self.activeError = error
        }
    }

    var isPresentingAlert: Binding<Bool> {
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
