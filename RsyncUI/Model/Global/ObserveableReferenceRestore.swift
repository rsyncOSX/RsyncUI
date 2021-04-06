//
//  ObserveableReferenceRestore.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 06/04/2021.
//

import Combine
import Foundation

class ObserveableReferenceRestore: ObservableObject {
    // When restore is ready set true
    @Published var isReady: Bool = false
    @Published var restorepath: String = ""
    @Published var typeofrestore = TypeofRestore.restorebyfiles
    // Combine
    var subscriptions = Set<AnyCancellable>()

    init() {
        $restorepath
            .debounce(for: .seconds(2), scheduler: globalMainQueue)
            .sink { [unowned self] path in
                validaterestorepath(path)
            }.store(in: &subscriptions)
        $typeofrestore
            .sink { [unowned self] type in
                validatetypeofrestore(type)
            }.store(in: &subscriptions)
    }

    func validaterestorepath(_: String) {}

    func validatetypeofrestore(_: TypeofRestore) {}
}

extension ObserveableReferenceRestore: PropogateError {
    func propogateerror(error: Error) {
        SharedReference.shared.errorobject?.propogateerror(error: error)
    }
}

enum RestoreError: LocalizedError {
    case error1
    case error2

    var errorDescription: String? {
        switch self {
        case .error1:
            return NSLocalizedString("Error1", comment: "Restore") + "..."
        case .error2:
            return NSLocalizedString("Error2", comment: "Restore") + "..."
        }
    }
}
