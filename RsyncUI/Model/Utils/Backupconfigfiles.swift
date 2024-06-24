//
//  Backupconfigfiles.swift
//  RsyncOSX
//
//  Created by Thomas Evensen on 09/10/2020.
//  Copyright © 2020 Thomas Evensen. All rights reserved.
//
// swiftlint:disable opening_brace

import Foundation
import SwiftUI

@MainActor
final class Backupconfigfiles {
    var fullpathnomacserial: String?
    var backuppath: String?

    func backup() {
        let fm = FileManager.default
        if let backuppath = backuppath,
           let fullpathnomacserial = fullpathnomacserial
        {
            let configurationsURL = URL(fileURLWithPath: fullpathnomacserial)
            let targetpath = "RsyncUIcopy-" + Date().shortlocalized_string_from_date()
            let backuppathURL = URL(fileURLWithPath: backuppath + "/" + targetpath)
            do {
                try fm.createDirectory(at: backuppathURL, withIntermediateDirectories: true)
                try fm.copyItem(at: configurationsURL, to: backuppathURL)
            } catch let e {
                let error = e
                propogateerror(error: error)
            }
        }
    }

    init() {
        let homepath = Homepath()
        fullpathnomacserial = homepath.fullpathnomacserial
        backuppath = homepath.documentscatalog
        backup()
    }
}

extension Backupconfigfiles {
    @MainActor func propogateerror(error: Error) {
        SharedReference.shared.errorobject?.alert(error: error)
    }
}

// swiftlint:enable opening_brace
