//
//  ActorCreateOutputforviewOutputRsync.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 02/07/2025.
//

import OSLog

actor ActorCreateOutputforviewOutputRsync {
    // From Array[String]
    @concurrent
    nonisolated func createaoutputforview(_ stringoutputfromrsync: [String]?) async -> [RsyncOutputData] {
        Logger.process.info("ActorCreateOutputforviewOutputRsync: createaoutputforview() MAIN THREAD: \(Thread.isMain) but on \(Thread.current)")
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
        Logger.process.info("ActorCreateOutputforviewOutputRsync: createaoutputforview() MAIN THREAD: \(Thread.isMain) but on \(Thread.current)")
        if let setoutputfromrsync {
            return setoutputfromrsync.map { line in
                RsyncOutputData(record: line)
            }
        }
        return []
    }
}
