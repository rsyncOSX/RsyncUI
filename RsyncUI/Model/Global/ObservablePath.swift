//
//  ObserveableReferencePaths.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 14/03/2021.
//

import Combine
import Foundation

@MainActor
final class ObservablePath: ObservableObject {
    // Environment
    @Published var environment: String = SharedReference.shared.environment ?? ""
    @Published var environmentvalue: String = SharedReference.shared.environmentvalue ?? ""

    // Combine
    var subscriptions = Set<AnyCancellable>()

    init() {
        $environment
            .debounce(for: .seconds(1), scheduler: globalMainQueue)
            .sink { environment in
                SharedReference.shared.environment = environment
            }.store(in: &subscriptions)
        $environmentvalue
            .debounce(for: .seconds(1), scheduler: globalMainQueue)
            .sink { environmentvalue in
                SharedReference.shared.environmentvalue = environmentvalue
            }.store(in: &subscriptions)
    }
}

extension ObservablePath {
    private func validatepath(_ path: String) throws -> Bool {
        if FileManager.default.fileExists(atPath: path, isDirectory: nil) == false {
            throw Validatedpath.nopath
        }
        return true
    }
}
