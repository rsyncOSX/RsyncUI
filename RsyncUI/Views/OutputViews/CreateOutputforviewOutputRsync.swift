//
//  CreateOutputforviewOutputRsync.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 20/03/2025.
//


import OSLog

actor CreateOutputforviewOutputRsync {
    // From Array[String]
    nonisolated func createoutputforviewoutputrsync(_ stringoutputfromrsync: [String]?) async -> [RsyncOutputData] {
        Logger.process.info("CreateOutputforviewOutputRsync: createoutputforviewoutputrsync() MAIN THREAD \(Thread.isMain)")

        if let data = stringoutputfromrsync {
            return data.map { line in
                RsyncOutputData(record: line)
            }
        }
        return []
    }

    // From Set<String>
    nonisolated func createoutputforviewoutputrsync(_ setoutputfromrsync: Set<String>?) async -> [RsyncOutputData] {
        Logger.process.info("CreateOutputforviewOutputRsync: createoutputforviewoutputrsync() MAIN THREAD \(Thread.isMain)")

        if let data = setoutputfromrsync {
            return data.map { line in
                RsyncOutputData(record: line)
            }
        }
        return []
    }
}
