//
//  ObservableRsyncOutput.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 04/10/2024.
//

import Observation

@Observable
final class ObservableRsyncOutput {
    var output = [RsyncOutputData]()

    func setoutput(_ stringoutputfromrsync: [String]?) {
        output.removeAll()
        if let stringoutputfromrsync {
            output = stringoutputfromrsync.map { filename in
                RsyncOutputData(record: filename)
            }
        }
    }
}
