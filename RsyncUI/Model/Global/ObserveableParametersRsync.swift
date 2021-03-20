//
//  ObserveableParametersRsync.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 20/03/2021.
//
// swiftlint:disable function_body_length

import Combine
import Foundation

class ObserveableParametersRsync: ObservableObject {
    // When property is changed set isDirty = true
    @Published var isDirty: Bool = false
    // Rsync parameters
    @Published var parameter8: String = ""
    @Published var parameter9: String = ""
    @Published var parameter10: String = ""
    @Published var parameter11: String = ""
    @Published var parameter12: String = ""
    @Published var parameter13: String = ""
    @Published var parameter14: String = ""
    // Selected configuration
    @Published var configuration: Configuration?
    // Value to check if input field is changed by user
    @Published var inputchangedbyuser: Bool = false
    // Combine
    var subscriptions = Set<AnyCancellable>()

    init() {
        $inputchangedbyuser
            .sink { _ in
            }.store(in: &subscriptions)
        $parameter8
            .debounce(for: .seconds(2), scheduler: globalMainQueue)
            .sink { [unowned self] parameter8 in
                validate(parameter8)
                isDirty = inputchangedbyuser
            }.store(in: &subscriptions)
        $parameter9
            .debounce(for: .seconds(2), scheduler: globalMainQueue)
            .sink { [unowned self] parameter9 in
                validate(parameter9)
                isDirty = inputchangedbyuser
            }.store(in: &subscriptions)
        $parameter10
            .debounce(for: .seconds(2), scheduler: globalMainQueue)
            .sink { [unowned self] parameter10 in
                validate(parameter10)
                isDirty = inputchangedbyuser
            }.store(in: &subscriptions)
        $parameter11
            .debounce(for: .seconds(2), scheduler: globalMainQueue)
            .sink { [unowned self] parameter11 in
                validate(parameter11)
                isDirty = inputchangedbyuser
            }.store(in: &subscriptions)
        $parameter12
            .debounce(for: .seconds(2), scheduler: globalMainQueue)
            .sink { [unowned self] parameter12 in
                validate(parameter12)
                isDirty = inputchangedbyuser
            }.store(in: &subscriptions)
        $parameter13
            .debounce(for: .seconds(2), scheduler: globalMainQueue)
            .sink { [unowned self] parameter13 in
                validate(parameter13)
                isDirty = inputchangedbyuser
            }.store(in: &subscriptions)
        $parameter14
            .debounce(for: .seconds(2), scheduler: globalMainQueue)
            .sink { [unowned self] parameter14 in
                validate(parameter14)
                isDirty = inputchangedbyuser
            }.store(in: &subscriptions)
        $configuration
            .sink { [unowned self] config in
                if let config = config {
                    setvalues(config)
                }
                isDirty = false
            }.store(in: &subscriptions)
    }

    private func validate(_ parameter: String) {
        print(parameter)
    }

    private func setvalues(_ config: Configuration) {
        parameter8 = config.parameter8 ?? ""
        parameter9 = config.parameter9 ?? ""
        parameter10 = config.parameter10 ?? ""
        parameter11 = config.parameter11 ?? ""
        parameter12 = config.parameter12 ?? ""
        parameter13 = config.parameter13 ?? ""
        parameter14 = config.parameter14 ?? ""
    }
}

extension ObserveableParametersRsync: PropogateError {
    func propogateerror(error: Error) {
        SharedReference.shared.errorobject?.propogateerror(error: error)
    }
}

enum ParameterError: LocalizedError {
    case notvalid

    var errorDescription: String? {
        switch self {
        case .notvalid:
            return NSLocalizedString("Not a valid ", comment: "ssh error") + "..."
        }
    }
}
