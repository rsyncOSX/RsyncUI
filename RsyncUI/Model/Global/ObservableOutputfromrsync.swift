//
//  ObservableOutputfromrsync.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 15/05/2024.
//

import SwiftUI

@Observable @MainActor
final class ObservableOutputfromrsync: PropogateError {
    var output = [Data]()

    struct Data: Identifiable {
        let id = UUID()
        var line: String
    }

    func outputistruncated(_ number: Int) -> Bool {
        do {
            if number > 20000 { throw OutputIsTruncated.istruncated }
        } catch let e {
            let error = e
            propogateerror(error: error)
            return true
        }
        return false
    }

    func generateoutput(_ data: [String]?) {
        var count = data?.count
        let summarycount = data?.count
        if count ?? 0 > 20000 { count = 20000 }
        // Show the 10,000 first lines
        for i in 0 ..< (count ?? 0) {
            if let line = data?[i] {
                output.append(Data(line: line))
            }
        }
        if outputistruncated(summarycount ?? 0) {
            output.append(Data(line: ""))
            output.append(Data(line: "**** Summary *****"))
            for i in ((summarycount ?? 0) - 20) ..< (summarycount ?? 0) - 1 {
                if let line = data?[i] {
                    output.append(Data(line: line))
                }
            }
        }
    }
}

enum OutputIsTruncated: LocalizedError {
    case istruncated

    var errorDescription: String? {
        switch self {
        case .istruncated:
            "Output from rsync was truncated"
        }
    }
}
