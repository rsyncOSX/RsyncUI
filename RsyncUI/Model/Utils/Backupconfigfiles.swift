//
//  Backupconfigfiles.swift
//  RsyncOSX
//
//  Created by Thomas Evensen on 09/10/2020.
//  Copyright © 2020 Thomas Evensen. All rights reserved.
//

import Foundation
import SwiftUI

@MainActor
final class Backupconfigfiles {
    let homepath = Homepath()
    var fullpathnomacserial: String?
    var backuppath: String?

    func backup() {
        let fm = FileManager.default
        if let backuppath,
           let fullpathnomacserial {
            let fullpathnomacserialURL = URL(fileURLWithPath: fullpathnomacserial)
            let targetpath = "RsyncUIcopy-" + Date().shortlocalized_string_from_date()
            let documentsURL = URL(fileURLWithPath: backuppath)
            let documentsbackuppathURL = documentsURL.appendingPathComponent(targetpath)
            do {
                try fm.copyItem(at: fullpathnomacserialURL, to: documentsbackuppathURL)
            } catch let err {
                let error = err
                homepath.propagateError(error: error)
            }
        }
    }

    init() {
        fullpathnomacserial = homepath.fullpathnomacserial
        backuppath = homepath.documentscatalog
        backup()
    }
}
