//
//  Profilenames.swift
//  RsyncSwiftUI
//
//  Created by Thomas Evensen on 01/03/2021.
//

import Foundation
import Observation

struct Profiles: Hashable, Identifiable {
    var profile: String?
    let id = UUID()

    init(_ name: String) {
        profile = name
    }
}

@Observable
final class Profilenames {
    var profiles: [Profiles] = .init()

    func update() {
        setprofilenames()
    }

    func setprofilenames() {
        let names = Homepath().getcatalogsasstringnames()
        for i in 0 ..< (names?.count ?? 0) {
            profiles.append(Profiles(names?[i] ?? ""))
        }
    }

    init() {
        setprofilenames()
    }
}
