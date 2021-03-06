//
//  NotYetImplemented.swift
//  RsyncSwiftUI
//
//  Created by Thomas Evensen on 24/02/2021.
//

import Foundation

enum EnumNotYetImplemented: LocalizedError {
    case notyetimplemented

    var errorDescription: String? {
        switch self {
        case .notyetimplemented:
            return NSLocalizedString("This function is not yet implemented", comment: "notyet") + "..."
        }
    }
}

final class NotYetImplemented {
    private func notyet() throws {
        throw EnumNotYetImplemented.notyetimplemented
    }

    init() {
        do {
            try notyet()
        } catch let e {
            let error = e
            self.propogateerror(error: error)
        }
    }
}

extension NotYetImplemented: PropogateError {
    func propogateerror(error: Error) {
        SharedReference.shared.errorobject?.propogateerror(error: error)
    }
}
