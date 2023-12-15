//
//  RsyncArguments.swift
//  RsyncOSX
//
//  Created by Thomas Evensen on 11/10/2019.
//  Copyright © 2019 Thomas Evensen. All rights reserved.
//

import Foundation

enum EnumRsyncArguments: String, CaseIterable, Identifiable, CustomStringConvertible {
    case backup = "--backup"
    case backupdir = "--backup-dir"
    case excludefrom = "--exclude-from"
    case exclude = "--exclude"
    case includefrom = "--include-from"
    case filesfrom = "--files-from"
    case maxsize = "--max-size"
    case suffix = "--suffix"
    case maxdelete = "--max-delete"
    case include = "--include"
    case filter = "--filter"
    case select

    var id: String { rawValue }
    var description: String { rawValue.localizedLowercase }
}

struct RsyncArguments {
    // Preselected parameters for storing a backup of deleted or changed files before
    // rsync synchronises the directories
    let backupstrings = ["--backup", "--backup-dir=~/backup", "--backup-dir=../backup"]
    let suffixstringfreebsd = "--suffix=_`date +'%Y-%m-%d.%H.%M'`"
    let suffixstringlinux = "--suffix=_$(date +%Y-%m-%d.%H.%M)"
}
