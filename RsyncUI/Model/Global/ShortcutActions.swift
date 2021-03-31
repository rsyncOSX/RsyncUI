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

    var multipletaskviewisactive: Bool = false
    var singetaskviewisactive: Bool = false

    func enablemultipletask() {
        print("enablemultipletask")
        multipletaskviewisactive = true
    }

    func disablemultipletask() {
        print("disablemultipletask")
        multipletaskviewisactive = false
    }

    func enablesingletask() {
        print("enablesingletask")
        singetaskviewisactive = true
    }

    func disablesingletask() {
        print("disablesingletask")
        singetaskviewisactive = false
    }

    init() {
        print("init")
    }

    deinit {
        print("deinit")
    }
}
