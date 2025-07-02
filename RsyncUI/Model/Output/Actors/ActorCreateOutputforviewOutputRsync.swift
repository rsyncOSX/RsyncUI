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
    nonisolated func createoutputforviewoutputrsync(_ stringoutputfromrsync: [String]?) async -> [RsyncOutputData] {
        Logger.process.info("CreateOutputforviewOutputRsync: createoutputforviewoutputrsync() MAIN THREAD: \(Thread.isMain) but on \(Thread.current)")

        if let data = stringoutputfromrsync {
            return data.map { line in
                RsyncOutputData(record: line)
            }
        }
        return []
    }

    // From Set<String>
    @concurrent
    nonisolated func createoutputforviewoutputrsync(_ setoutputfromrsync: Set<String>?) async -> [RsyncOutputData] {
        Logger.process.info("CreateOutputforviewOutputRsync: createoutputforviewoutputrsync() MAIN THREAD: \(Thread.isMain) but on \(Thread.current)")

        if let data = setoutputfromrsync {
            return data.map { line in
                RsyncOutputData(record: line)
            }
        }
        return []
    }
}
