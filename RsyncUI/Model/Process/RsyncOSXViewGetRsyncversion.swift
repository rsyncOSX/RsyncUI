//
//  RsyncOSXViewGetRsyncversion.swift
//  RsyncSwiftUI
//
//  Created by Thomas Evensen on 18/01/2021.
//

import Foundation

// Getting and setting the rsync version.
final class RsyncOSXViewGetRsyncversion: ObservableObject, UpdateRsyncVersionString {
    var rsyncversion = ""

    func update() {
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
