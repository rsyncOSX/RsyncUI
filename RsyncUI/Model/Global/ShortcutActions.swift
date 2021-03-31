//
//  ShortcutActions.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 30/03/2021.
//

import Foundation

final class ShortcutActions: ObservableObject {
    @Published var executemultipletasks: Bool = false
    @Published var estimatemultipletasks: Bool = false
    @Published var executesingletask: Bool = false
    @Published var estimatesingletask: Bool = false

    var multipletaskisactive: Bool = false
    var singetaskisactive: Bool = false

    func enablemultipletask() {
        multipletaskisactive = true
    }

    func disablemultipletask() {
        multipletaskisactive = false
    }

    func enablesingletask() {
        singetaskisactive = true
    }

    func disablesingletask() {
        singetaskisactive = false
    }
}
