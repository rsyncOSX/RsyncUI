//
//  CreateOutputforView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 02/07/2025.
//

import OSLog

struct CreateOutputforView {
    /// From Array[String]
    func createOutputForView(_ stringoutputfromrsync: [String]?) -> [RsyncOutputData] {
        Logger.process.debugThreadOnly("CreateOutputforView: createaoutputforview()")
        if let stringoutputfromrsync {
            return stringoutputfromrsync.map { line in
                RsyncOutputData(record: line)
            }
        }
        return []
    }

    /// Show filelist for Restore, the TrimOutputForRestore prepares list
    func createoutputforrestore(_ stringoutputfromrsync: [String]?) async -> [RsyncOutputData] {
        Logger.process.debugThreadOnly("CreateOutputforView: createoutputforrestore()")
        if let stringoutputfromrsync {
            if let trimmeddata = await TrimOutputForRestore(stringoutputfromrsync).trimmeddata {
                return trimmeddata.map { filename in
                    RsyncOutputData(record: filename)
                }
            }
        }
        return []
    }

    /// After a restore, present files
    func createoutputafterrestore(_ stringoutputfromrsync: [String]?) -> [RsyncOutputData] {
        Logger.process.debugThreadOnly("CreateOutputforView: createoutputafterrestore()")
        if let stringoutputfromrsync {
            return stringoutputfromrsync.map { filename in
                RsyncOutputData(record: filename)
            }
        }
        return []
    }

    /// Logfile
    func createaoutputlogfileforview() async -> [LogfileRecords] {
        Logger.process.debugThreadOnly("CreateOutputforView: createaoutputlogfileforview()")
        if let data = await ActorLogToFile().readloggfile() {
            return data.map { record in
                LogfileRecords(line: record)
            }
        } else {
            return []
        }
    }
}
