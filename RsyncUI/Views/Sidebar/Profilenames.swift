//
//  Profilenames.swift
//  RsyncSwiftUI
//
//  Created by Thomas Evensen on 01/03/2021.
//

import Foundation

struct Profiles: Identifiable, Hashable {
    var id = UUID()
    var profile: String?

    init(_ name: String) {
        profile = name
    }
}

final class Profilenames: ObservableObject {
    @Published var profiles: [Profiles]?

    func update() {
        setprofilenames()
        objectWillChange.send()
    }

    func setprofilenames() {
        let names = Catalogsandfiles(profileorsshrootpath: .profileroot).getcatalogsasstringnames()
        profiles = []
        for i in 0 ..< (names?.count ?? 0) {
            profiles?.append(Profiles(names?[i] ?? ""))
        }
    }

    init() {
        setprofilenames()
    }
}
