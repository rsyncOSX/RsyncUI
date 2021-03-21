//
//  SuffixstringsRsyncParameters.swift
//  RsyncOSX
//
//  Created by Thomas Evensen on 11/10/2019.
//  Copyright © 2019 Thomas Evensen. All rights reserved.
//
// swiftlint:disable trailing_comma

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
    case deleteexcluded = "--delete-excluded"
    case include = "--include"
    case filter = "--filter"
    case none

    var id: String { rawValue }
    var description: String { rawValue.localizedLowercase }
}

struct RsyncArguments {
    // Preselected parameters for storing a backup of deleted or changed files before
    // rsync synchronises the directories
    let backupstrings = ["--backup", "--backup-dir=../backup"]
    let suffixstringfreebsd = "--suffix=_`date +'%Y-%m-%d.%H.%M'`"
    let suffixstringlinux = "--suffix=_$(date +%Y-%m-%d.%H.%M)"

    // Tuple for rsync argument and value
    typealias Argument = (String, Int)
    // Static initial arguments
    let arguments: [Argument] = [
        ("--backup", 0),
        ("--backup-dir", 1),
        ("--exclude-from", 1),
        ("--exclude", 1),
        ("--include-from", 1),
        ("--files-from", 1),
        ("--max-size", 1),
        ("--suffix", 1),
        ("--max-delete", 1),
        ("--delete-excluded", 0),
        ("--include", 1),
        ("--filter", 1),
    ]
}
