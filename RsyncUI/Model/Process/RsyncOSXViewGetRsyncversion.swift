//
//  RsyncOSXViewGetRsyncversion.swift
//  RsyncSwiftUI
//
//  Created by Thomas Evensen on 18/01/2021.
//

import Foundation

// Getting and setting the rsync version.
final class RsyncOSXViewGetRsyncversion: ObservableObject, UpdateRsyncVersionString {
    @Published var rsyncversion = ""

    func reload() {
        objectWillChange.send()
    }

    func update(_ ver3: Bool) {
        // Must set new valuesa ahead of save to get correct string
        SharedReference.shared.rsyncversion3 = ver3
        _ = RsyncVersionString(object: self)
        objectWillChange.send()
    }

    func updatersyncversionstring(rsyncversion: String) {
        self.rsyncversion = rsyncversion
        objectWillChange.send()
    }

    init() {
        _ = RsyncVersionString(object: self)
    }
}
