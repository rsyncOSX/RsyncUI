//
//  Profilenames.swift
//  RsyncSwiftUI
//
//  Created by Thomas Evensen on 01/03/2021.
//

import Foundation
import Observation

struct ProfilesnamesRecord: Hashable, Identifiable {
    var profile: String?
    let id = UUID()

    init(_ name: String) {
        profile = name
    }
}

@Observable @MainActor
final class Profilenames {
    var profiles: [ProfilesnamesRecord] = .init()

    func update() {
        setprofilenames()
    }

    func setprofilenames() {
        let names = Homepath().getfullpathmacserialcatalogsasstringnames()
        for i in 0 ..< (names?.count ?? 0) {
            profiles.append(ProfilesnamesRecord(names?[i] ?? ""))
        }
    }

    init() {
        setprofilenames()
    }
}
