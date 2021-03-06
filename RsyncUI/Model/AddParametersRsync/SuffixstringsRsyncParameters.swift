//
//  SuffixstringsRsyncParameters.swift
//  RsyncOSX
//
//  Created by Thomas Evensen on 11/10/2019.
//  Copyright © 2019 Thomas Evensen. All rights reserved.
//
// swiftlint:disable trailing_comma

import Foundation
struct SuffixstringsRsyncParameters {
    // Preselected parameters for storing a backup of deleted or changed files before
    // rsync synchronises the directories
    let backupstrings = ["--backup", "--backup-dir=../backup"]
    let suffixstringfreebsd = "--suffix=_`date +'%Y-%m-%d.%H.%M'`"
    let suffixstringlinux = "--suffix=_$(date +%Y-%m-%d.%H.%M)"

    // Tuple for rsync argument and value
    typealias Argument = (String, Int)
    // Static initial arguments, DO NOT change order
    let rsyncArguments: [Argument] = [
        ("user", 1),
        ("delete", 0),
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
