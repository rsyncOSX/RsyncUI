//
//  outputProcess.swift
//
//  Created by Thomas Evensen on 11/01/16.
//  Copyright © 2016 Thomas Evensen. All rights reserved.
//
//  swiftlint:disable cyclomatic_complexity

import Foundation
import SwiftUI

struct Outputrecord: Identifiable {
    var id = UUID()
    var line: String
}

enum Rsyncerror: LocalizedError {
    case rsyncerror

    var errorDescription: String? {
        switch self {
        case .rsyncerror:
            return NSLocalizedString("There are errors in output", comment: "rsync error") + "..."
        }
    }
}

enum Trim {
    case one
    case two
    case three
    case four
}

class OutputProcess {
    var output: [String]?
    var trimmedoutput: [String]?
    var startindex: Int?
    var maxnumber: Int = 0
    var errordiscovered: Bool = false

    // Error handling
    func checkforrsyncerror(_ line: String) throws {
        let error = line.contains("rsync error:")
        if error {
            throw Rsyncerror.rsyncerror
        }
    }

    func getMaxcount() -> Int {
        if trimmedoutput == nil {
            _ = trimoutput(trim: .two)
        }
        return maxnumber
    }

    func count() -> Int {
        return output?.count ?? 0
    }

    func getrawOutput() -> [String]? {
        return output
    }

    func getOutput() -> [String]? {
        if trimmedoutput != nil {
            return trimmedoutput
        } else {
            return output
        }
    }

    func addlinefromoutput(str: String) {
        if startindex == nil {
            startindex = 0
        } else {
            startindex = output?.count ?? 0 + 1
        }
        str.enumerateLines { line, _ in
            self.output?.append(line)
        }
    }

    func trimoutput(trim: Trim) -> [String]? {
        var out = [String]()
        guard output != nil else { return nil }
        switch trim {
        case .one:
            for i in 0 ..< (output?.count ?? 0) {
                if let substr = output?[i].dropFirst(10).trimmingCharacters(in: .whitespacesAndNewlines) {
                    let str = substr.components(separatedBy: " ").dropFirst(3).joined(separator: " ")
                    if str.isEmpty == false, str.contains(".DS_Store") == false {
                        out.append("./" + str)
                    }
                }
            }
        case .two:
            for i in 0 ..< (output?.count ?? 0) where output?[i].last != "/" {
                out.append(self.output?[i] ?? "")
                do {
                    try checkforrsyncerror(self.output?[i] ?? "")
                } catch let e {
                    // Only want one notification about error
                    if errordiscovered == false {
                        let error = e
                        _ = Logfile(self, true)
                        self.propogateerror(error: error)
                        errordiscovered = true
                    }
                }
            }
            maxnumber = out.count
        case .three:
            for i in 0 ..< (output?.count ?? 0) {
                if let substr = output?[i].dropFirst(10).trimmingCharacters(in: .whitespacesAndNewlines) {
                    let str = substr.components(separatedBy: " ").dropFirst(3).joined(separator: " ")
                    if str.isEmpty == false {
                        if str.contains(".DS_Store") == false {
                            out.append(str)
                        }
                    }
                }
            }
        case .four:
            for i in 0 ..< (output?.count ?? 0) {
                if let substr = output?[i].dropFirst(10).trimmingCharacters(in: .whitespacesAndNewlines) {
                    let str = substr.components(separatedBy: " ").dropFirst(1).dropLast(2).joined(separator: " ")
                    if str.count > 4, str.contains(".DS_Store") == false {
                        out.append(str)
                    }
                }
            }
        }
        trimmedoutput = out
        return out
    }

    init() {
        output = [String]()
    }
}

extension OutputProcess: PropogateError {
    func propogateerror(error: Error) {
        SharedReference.shared.errorobject?.propogateerror(error: error)
    }
}
