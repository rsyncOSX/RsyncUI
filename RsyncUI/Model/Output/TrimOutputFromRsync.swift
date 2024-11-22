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
final class TrimOutputFromRsync: PropogateError {
    var trimmeddata: [String]?
    var errordiscovered: Bool = false

    // Error handling
    func checkforrsyncerror(_ line: String) throws {
        let error = line.contains("rsync error:")
        if error {
            throw Rsyncerror.rsyncerror
        }
    }

    init(_ stringoutputfromrsync: [String]) {
        trimmeddata = stringoutputfromrsync.compactMap { line in
            do {
                try checkforrsyncerror(line)
            } catch let e {
                // Only want one notification about error, not multiple
                // Multiple can be a kind of race situation
                if errordiscovered == false {
                    let error = e
                    _ = Logfile(stringoutputfromrsync, error: true)
                    propogateerror(error: error)
                    errordiscovered = true
                }
            }
            return (line.last != "/") ? line : nil
        }
    }
    
    init() {}
}
