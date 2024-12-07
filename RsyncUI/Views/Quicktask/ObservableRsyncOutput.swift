//
//  ObservableRsyncOutput.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 04/10/2024.
//

import Observation

@Observable
final class ObservableRsyncOutput {
    var output: [RsyncOutputData]?
}

actor CreateOutputforview {
    func createaoutputforview(_ stringoutputfromrsync: [String]?) async -> [RsyncOutputData] {
        if let stringoutputfromrsync {
            return stringoutputfromrsync.map { filename in
                RsyncOutputData(record: filename)
            }
        }
        return []
    }
}
