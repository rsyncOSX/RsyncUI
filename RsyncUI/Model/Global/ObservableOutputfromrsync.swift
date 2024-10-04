//
//  ObservableOutputfromrsync.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 15/05/2024.
//

import SwiftUI

struct RsyncOutputData: Identifiable, Equatable, Hashable {
    let id = UUID()
    var line: String
}

@Observable @MainActor
final class ObservableOutputfromrsync: PropogateError {
    var output = [RsyncOutputData]()
    let maxcount = 10000

    func outputistruncated(_ number: Int) throws {
        guard number < maxcount else {
            throw OutputIsTruncated.istruncated
        }
    }

    func generateoutput(_ stringoutputfromrsync: [String]?) {
        if let data = stringoutputfromrsync, data.count < maxcount {
            self.output = data.map({ line in
                RsyncOutputData(line: line)
            })
        } else if let data = stringoutputfromrsync {
            let suboutput = Array(data[0 ..< maxcount]) + Array(data[data.count - 20 ..< data.count])
            self.output = suboutput.map({ line in
                RsyncOutputData(line: line)
            })
            do {
                try outputistruncated(data.count)
            } catch let e {
                let error = e
                propogateerror(error: error)
                return
            }
        }
    }
}

enum OutputIsTruncated: LocalizedError {
    case istruncated

    var errorDescription: String? {
        switch self {
        case .istruncated:
            "Output from rsync is truncated\n more than 10,000 rows\n last 20 rows are included in output"
        }
    }
}
