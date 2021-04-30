//
//  Backupconfigfiles.swift
//  RsyncOSX
//
//  Created by Thomas Evensen on 09/10/2020.
//  Copyright © 2020 Thomas Evensen. All rights reserved.
//
// swiftlint:disable opening_brace

import Files
import Foundation
import SwiftUI

final class Backupconfigfiles {
    var usedpath: String?
    var backuppath: String?

    func backup() {
        if let documentscatalog = backuppath,
           let usedpath = self.usedpath
        {
            var originFolder: Folder?
            do {
                originFolder = try Folder(path: usedpath)
                let targetpath = "RsyncUIcopy-" + Date().shortlocalized_string_from_date()
                let targetFolder = try Folder(path: documentscatalog).createSubfolder(at: targetpath)
                try originFolder?.copy(to: targetFolder)
            } catch let e {
                let error = e
                self.propogateerror(error: error)
            }
        }
    }

    init() {
        let path = NamesandPaths(profileorsshrootpath: .profileroot)
        usedpath = path.fullrootnomacserial
        backuppath = path.documentscatalog
        backup()
    }
}

extension Backupconfigfiles: PropogateError {
    func propogateerror(error: Error) {
        SharedReference.shared.errorobject?.propogateerror(error: error)
    }
}
