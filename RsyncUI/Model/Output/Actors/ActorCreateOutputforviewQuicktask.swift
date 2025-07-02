//
//  ActorCreateOutputforviewQuicktask.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 02/07/2025.
//

import Observation
import OSLog

actor ActorCreateOutputforviewQuicktask {
    @concurrent
    nonisolated func createaoutputforview(_ stringoutputfromrsync: [String]?) async -> [RsyncOutputData] {
        Logger.process.info("CreateOutputforview: createaoutputforview() MAIN THREAD: \(Thread.isMain) but on \(Thread.current)")
        if let stringoutputfromrsync {
            return stringoutputfromrsync.map { filename in
                RsyncOutputData(record: filename)
            }
        }
        return []
    }
}
