//
//  Neworoldprofilepath.swift
//  RsyncOSX
//
//  Created by Thomas Evensen on 29/08/2020.
//  Copyright © 2020 Thomas Evensen. All rights reserved.
//

import Files
import Foundation

struct Neworoldprofilepath {
    var oldpath: String?
    var newpath: String?
    var usenewpath: Bool = false
    var useoldpath: Bool = false

    func verifyoldpath() -> Bool {
        if let oldpath = self.oldpath {
            do {
                _ = try Folder(path: oldpath)
                return true
            } catch {
                return false
            }
        }
        return false
    }

    func verifynewpath() -> Bool {
        if let newpath = self.newpath {
            do {
                _ = try Folder(path: newpath)
                return true
            } catch {
                return false
            }
        }
        return false
    }

    init() {
        SharedReference.shared.usenewconfigpath = false
        oldpath = NamesandPaths(profileorsshrootpath: .profileroot).fullroot
        SharedReference.shared.usenewconfigpath = true
        newpath = NamesandPaths(profileorsshrootpath: .profileroot).fullroot
        useoldpath = verifyoldpath()
        usenewpath = verifynewpath()
        switch (useoldpath, usenewpath) {
        case (true, true):
            SharedReference.shared.usenewconfigpath = true
        case (true, false):
            SharedReference.shared.usenewconfigpath = false
        case (false, false):
            SharedReference.shared.usenewconfigpath = true
        default:
            SharedReference.shared.usenewconfigpath = true
        }
    }
}
