//
//  ObservableRsyncOutput.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 04/10/2024.
//

import Observation
import OSLog

@Observable
final class ObservableRsyncOutput {
    var output: [RsyncOutputData]?
}

actor CreateOutputforview {
    func createaoutputforview(_ stringoutputfromrsync: [String]?) async -> [RsyncOutputData] {
        Logger.process.info("CreateOutputforview: createaoutputforview() MAIN THREAD \(Thread.isMain)")
        if let stringoutputfromrsync {
            return stringoutputfromrsync.map { filename in
                RsyncOutputData(record: filename)
            }
        }
        return []
    }
}
