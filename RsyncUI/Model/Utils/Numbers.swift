//
//  Numbers.swift
//  RsyncOSX
//
//  Created by Thomas Evensen on 22.05.2017.
//  Copyright © 2017 Thomas Evensen. All rights reserved.
//
//  Class for crunching numbers from rsyn output.  Numbers are
//  informal only, either used in main view or for logging purposes.
//
// swiftlint:disable cyclomatic_complexity

import Foundation
import ParseRsyncOutput

// enum for returning what is asked for
enum EnumNumbers {
    case totalNumber
    case totalDirs
    case totalNumber_totalDirs
    case totalNumberSizebytes
    case transferredNumber
    case transferredNumberSizebytes
    case new
    case delete
}

@MainActor
final class Numbers {
    var parsersyncoutput: ParseRsyncOutput?
    var stats: String?

    // Get numbers from rsync (dry run)
    func getTransferredNumbers(numbers: EnumNumbers) -> Int {
        switch numbers {
        case .totalDirs:
            return parsersyncoutput?.numbersonly?.totDir ?? 0
        case .totalNumber:
            return parsersyncoutput?.numbersonly?.totNum ?? 0
        case .transferredNumber:
            return parsersyncoutput?.numbersonly?.transferNum ?? 0
        case .totalNumberSizebytes:
            let size = parsersyncoutput?.numbersonly?.totNumSize ?? 0
            return Int(size)
        case .transferredNumberSizebytes:
            let size = parsersyncoutput?.numbersonly?.transferNumSize ?? 0
            return Int(size)
        case .new:
            let num = parsersyncoutput?.numbersonly?.newfiles ?? 0
            return Int(num)
        case .delete:
            let num = parsersyncoutput?.numbersonly?.deletefiles ?? 0
            return Int(num)
        case .totalNumber_totalDirs:
            return (parsersyncoutput?.numbersonly?.totDir ?? 0) + (parsersyncoutput?.numbersonly?.totNum ?? 0)
        }
    }

    init(_ myoutput: [String]?) {
        if let myoutput {
            guard myoutput.count > 0 else { return }
            let trimmedoutputfromrsync = TrimOutputFromRsync(myoutput).trimmeddata
            parsersyncoutput = ParseRsyncOutput(trimmedoutputfromrsync, SharedReference.shared.rsyncversion3)
            stats = parsersyncoutput?.stats
        }
    }
}

// swiftlint:enable cyclomatic_complexity
