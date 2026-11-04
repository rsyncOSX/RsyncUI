//
//  MyEnvironment.swift
//  RsyncUI
//

import Foundation

@MainActor
struct MyEnvironment {
    var environment: [String: String]?

    init?() {
        if let environment = SharedReference.shared.environment, let environmentvalue = SharedReference.shared.environmentvalue {
            self.environment = [environment: environmentvalue]
        }
    }
}
