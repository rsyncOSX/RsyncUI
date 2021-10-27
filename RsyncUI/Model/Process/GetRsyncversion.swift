//
//  RsyncOSXViewGetRsyncversion.swift
//  RsyncSwiftUI
//
//  Created by Thomas Evensen on 18/01/2021.
//

import Foundation

// Getting and setting the rsync version.
final class GetRsyncversion: ObservableObject, UpdateRsyncVersionString {
    
    @Published var rsyncversion = ""

    /*
    func update(_ ver: Bool) {
        // Must set new valuesa ahead of save to get correct string
        SharedReference.shared.reload = false
        SharedReference.shared.rsyncversion3 = ver
        _ = RsyncVersionString(object: self)
    }
     */
    
    func updatersyncversionstring(rsyncversion: String) {
        SharedReference.shared.reload = false
        self.rsyncversion = rsyncversion
    }

    init() {
        SharedReference.shared.reload = false
        _ = RsyncVersionString(object: self)
    }
}
