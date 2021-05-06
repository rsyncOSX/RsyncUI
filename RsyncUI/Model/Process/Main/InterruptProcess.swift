//
//  InterruptProcess.swift
//  RsyncOSX
//
//  Created by Thomas Evensen on 18/06/2020.
//  Copyright © 2020 Thomas Evensen. All rights reserved.
//

import Foundation

struct InterruptProcess {
    init() {
        guard SharedReference.shared.process != nil else { return }
        let string: [String] = ["Interrupted: " + Date().long_localized_string_from_date()]
        _ = Logfile(string)
        SharedReference.shared.process?.interrupt()
        SharedReference.shared.process = nil
    }

    init(output: OutputfromProcess?) {
        guard SharedReference.shared.process != nil, output != nil else { return }
        _ = Logfile(output?.getOutput())
        SharedReference.shared.process?.interrupt()
        SharedReference.shared.process = nil
    }
}
