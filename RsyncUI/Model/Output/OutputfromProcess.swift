//
//  OutputfromProcess.swift
//
//  Created by Thomas Evensen on 11/01/16.
//  Copyright © 2016 Thomas Evensen. All rights reserved.
//

import Foundation

class OutputfromProcess {
    var output: [String]?

    func getOutput() -> [String]? {
        output
    }

    func addlinefromoutput(str: String) {
        str.enumerateLines { line, _ in
            self.output?.append(line)
        }
    }

    init() {
        output = [String]()
    }
}

extension String: @retroactive Identifiable { public var id: String { self } }
