//
//  OutputfromRsync.swift
//  RsyncSwiftUI
//
//  Created by Thomas Evensen on 01/02/2021.
//

// Observed object to keep output from rsync

import Foundation

final class OutputFromRsync: ObservableObject {
    private var output: [String]?

    func setoutput(output: [String]?) {
        self.output = output
    }

    func getoutput() -> [String]? {
        return output
    }

    func resetoutput() {
        output = nil
    }
}
