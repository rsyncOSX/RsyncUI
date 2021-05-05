//
//  outputProcess.swift
//
//  Created by Thomas Evensen on 11/01/16.
//  Copyright © 2016 Thomas Evensen. All rights reserved.
//

import Foundation
import SwiftUI

class OutputProcess {
    var output: [String]?
    var startindex: Int?

    func getOutput() -> [String]? {
        return output
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

    init() {
        output = [String]()
    }
}

extension OutputProcess: PropogateError {
    func propogateerror(error: Error) {
        SharedReference.shared.errorobject?.propogateerror(error: error)
    }
}

extension String: Identifiable { public var id: String { self } }
