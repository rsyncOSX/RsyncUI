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
        Logger.process.debugThreadOnly("ActorCreateOutputforView: createaoutputforview()")
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
        Logger.process.debugThreadOnly("ActorCreateOutputforView: createaoutputforview()")
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
        Logger.process.debugThreadOnly("ActorCreateOutputforView: createoutputforrestore()")
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
        Logger.process.debugThreadOnly("ActorCreateOutputforView: createoutputafterrestore()")
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
        Logger.process.debugThreadOnly("ActorCreateOutputforView: createaoutputlogfileforview()")
        if let data = await ActorLogToFile().readloggfile() {
            return data.map { record in
                LogfileRecords(line: record)
            }
        } else {
            return []
        }
    }

    // $Home/rsync-output.log
    @concurrent
    nonisolated func createaoutputrsynclogforview() async -> [LogfileRecords] {
        Logger.process.debugThreadOnly("ActorCreateOutputforView: createaoutputrsynclog()")

        if let logURL = URL.userHomeDirectoryURLPath?.appendingPathComponent("rsync-output.log") {
            do {
                let data = try Data(contentsOf: logURL)
                let logfile = String(data: data, encoding: .utf8)
                if let rsyncOutputLog = logfile.map({ line in
                    line.components(separatedBy: .newlines)
                }) {
                    return rsyncOutputLog.map { record in
                        LogfileRecords(line: record)
                    }
                }
            } catch {}
        }
        return []
    }
}
