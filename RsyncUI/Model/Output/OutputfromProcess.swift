//
//  OutputfromProcess.swift
//
//  Created by Thomas Evensen on 11/01/16.
//  Copyright © 2016 Thomas Evensen. All rights reserved.
//

import Foundation

final class OutputfromProcess {
    var output: [String]?

    func addlinefromoutput(str: String) {
        str.enumerateLines { line, _ in
            self.output?.append(line)
        }
    }

    init() {
        output = [String]()
    }
}
