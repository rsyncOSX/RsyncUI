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

final class Backupconfigfiles {
    var usedpath: String?
    var backuppath: String?

    func backup() {
        if let documentscatalog = backuppath,
           let usedpath = usedpath
        {
            var originFolder: Folder?
            do {
                originFolder = try Folder(path: usedpath)
                let targetpath = "RsyncUIcopy-" + Date().shortlocalized_string_from_date()
                let targetFolder = try Folder(path: documentscatalog).createSubfolder(at: targetpath)
                try originFolder?.copy(to: targetFolder)
            } catch let e {
                let error = e
                propogateerror(error: error)
            }
        }
    }

    init() {
        let path = NamesandPaths(.configurations)
        usedpath = path.fullpathnomacserial
        backuppath = path.documentscatalog
        backup()
    }
}

extension Backupconfigfiles {
    func propogateerror(error: Error) {
        SharedReference.shared.errorobject?.alert(error: error)
    }
}

// swiftlint:enable opening_brace
