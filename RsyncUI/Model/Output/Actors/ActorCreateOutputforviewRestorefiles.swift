//
//  CreateOutputforviewRestorefiles.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 02/07/2025.
//

import OSLog

actor ActorCreateOutputforviewRestorefiles {
    // Show filelist for Restore, the TrimOutputForRestore prepares list
    @concurrent
    nonisolated func createoutputforview(_ stringoutputfromrsync: [String]?) async -> [RsyncOutputData] {
        Logger.process.info("CreateOutputforviewRestorefiles: createoutputforview()  MAIN THREAD: \(Thread.isMain) but on \(Thread.current)")
        if let stringoutputfromrsync {
            if let trimmeddata = await TrimOutputForRestore(stringoutputfromrsync).trimmeddata {
                return trimmeddata.map { filename in
                    RsyncOutputData(record: filename)
                }
            }
        }
        return []
    }

    // After a restore, present files
    @concurrent
    nonisolated func createrestoredfilesoutputforview(_ stringoutputfromrsync: [String]?) async -> [RsyncOutputData] {
        Logger.process.info("CreateOutputforviewRestorefiles: createrestoredfilesoutputforview() MAIN THREAD: \(Thread.isMain) but on \(Thread.current)")
        if let stringoutputfromrsync {
            return stringoutputfromrsync.map { filename in
                RsyncOutputData(record: filename)
            }
        }
        return []
    }
}
