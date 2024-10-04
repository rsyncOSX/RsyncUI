//
//  ObservableRsyncOutput.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 04/10/2024.
//

import Observation


@Observable
final class ObservableRsyncOutput {
    private var output = [RsyncOutputData]()

    func setoutput(_ data: [String]?) {
        output.removeAll()
        if let data = data {
            output = data.map { filename in
                RsyncOutputData(line: filename)
            }
        }
    }

    func getoutput() -> [RsyncOutputData] {
        output
    }
}
