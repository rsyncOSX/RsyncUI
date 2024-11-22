//
//  TrimOutputFromRsync.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 05/05/2021.
//

import Foundation

enum Rsyncerror: LocalizedError {
    case rsyncerror

    var errorDescription: String? {
        switch self {
        case .rsyncerror:
            "There are errors in output from rsync"
        }
    }
}

@MainActor
final class TrimOutputFromRsync {
    var trimmeddata: [String]?

    // Check for error in output form rsync
    func checkforrsyncerror(_ line: String) throws {
        let error = line.contains("rsync error:")
        if error {
            throw Rsyncerror.rsyncerror
        }
    }

    init(_ stringoutputfromrsync: [String]) {
        trimmeddata = stringoutputfromrsync.compactMap { line in
            line.hasSuffix("/") == false ? line : nil
        }
    }

    init() {}
}
