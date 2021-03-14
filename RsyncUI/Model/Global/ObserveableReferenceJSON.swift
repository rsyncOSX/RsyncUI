//
//  ObserveableReferenceJSON.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 14/03/2021.
//
// swiftlint:disable function_body_length type_body_length

import Combine
import Foundation

class ObserveableReferenceJSON: ObservableObject {
    // When property is changed set isDirty = true
    @Published var isDirty: Bool = false
    // Read configurations and schedules as JSON or not
    @Published var json: Bool = SharedReference.shared.json
    // Value to check if input field is changed by user
    @Published var inputchangedbyuser: Bool = false
    // Combine
    var subscriptions = Set<AnyCancellable>()

    init() {
        $inputchangedbyuser
            .sink { _ in
            }.store(in: &subscriptions)
        $json
            .debounce(for: .milliseconds(500), scheduler: globalMainQueue)
            .sink { [unowned self] json in
                SharedReference.shared.json = json
                isDirty = inputchangedbyuser
            }.store(in: &subscriptions)
    }
}
