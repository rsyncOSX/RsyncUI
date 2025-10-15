//
//  ActorCreateOutputforView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 02/07/2025.
//

import OSLog

actor ActorCreateOutputforView {
    // From Array[String]
    @concurrent
    nonisolated func createaoutputforview(_ stringoutputfromrsync: [String]?) async -> [RsyncOutputData] {
        Logger.process.info("ActorCreateOutputforView: createaoutputforview() MAIN THREAD: \(Thread.isMain, privacy: .public) but on \(Thread.current, privacy: .public)")
        if let stringoutputfromrsync {
            return stringoutputfromrsync.map { line in
                RsyncOutputData(record: line)
            }
        }
        return []
    }

    // From Set<String>
    @concurrent
    nonisolated func createaoutputforview(_ setoutputfromrsync: Set<String>?) async -> [RsyncOutputData] {
        Logger.process.info("ActorCreateOutputforView: createaoutputforview() MAIN THREAD: \(Thread.isMain, privacy: .public) but on \(Thread.current, privacy: .public)")
        if let setoutputfromrsync {
            return setoutputfromrsync.map { line in
                RsyncOutputData(record: line)
            }
        }
        return []
    }

    // Show filelist for Restore, the TrimOutputForRestore prepares list
    @concurrent
    nonisolated func createoutputforrestore(_ stringoutputfromrsync: [String]?) async -> [RsyncOutputData] {
        Logger.process.info("ActorCreateOutputforView: createoutputforrestore()  MAIN THREAD: \(Thread.isMain, privacy: .public) but on \(Thread.current, privacy: .public)")
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
    nonisolated func createoutputafterrestore(_ stringoutputfromrsync: [String]?) async -> [RsyncOutputData] {
        Logger.process.info("ActorCreateOutputforView: createoutputafterrestore() MAIN THREAD: \(Thread.isMain, privacy: .public) but on \(Thread.current, privacy: .public)")
        if let stringoutputfromrsync {
            return stringoutputfromrsync.map { filename in
                RsyncOutputData(record: filename)
            }
        }
        return []
    }

    // Logfile
    @concurrent
    nonisolated func createaoutputlogfileforview() async -> [LogfileRecords] {
        Logger.process.info("ActorCreateOutputforView: createaoutputlogfileforview() generatedata() MAIN THREAD: \(Thread.isMain, privacy: .public) but on \(Thread.current, privacy: .public)")
        if let data = await ActorLogToFile(false).readloggfile() {
            return data.map { record in
                LogfileRecords(line: record)
            }
        } else {
            return []
        }
    }
}
