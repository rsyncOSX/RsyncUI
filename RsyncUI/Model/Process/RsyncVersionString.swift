//
//  RsyncVersionString.swift
//  RsyncOSX
//
//  Created by Thomas Evensen on 27.12.2017.
//  Copyright © 2017 Thomas Evensen. All rights reserved.
//
// swiftlint:disable opening_brace

import Foundation

protocol UpdateRsyncVersionString: AnyObject {
    func updatersyncversionstring(rsyncversion: String)
}

final class RsyncVersionString {
    var outputprocess: OutputProcess?
    var rsyncversionshort: String?
    var rsyncversionstring: String?
    weak var updateRsyncVersionStringDelegate: UpdateRsyncVersionString?

    init(object: UpdateRsyncVersionString?) {
        updateRsyncVersionStringDelegate = object
        if SharedReference.shared.norsync == false {
            outputprocess = OutputProcess()
            let command = RsyncProcessCmdClosure(arguments: ["--version"],
                                                 config: nil,
                                                 processtermination: processtermination,
                                                 filehandler: filehandler)
            command.executeProcess(outputprocess: outputprocess)
        }
    }
}

extension RsyncVersionString {
    func processtermination() {
        guard outputprocess?.getOutput()?.count ?? 0 > 0 else { return }
        if let rsyncversionshort = outputprocess?.getOutput()?[0],
           let rsyncversionstring = outputprocess?.getOutput()?.joined(separator: "\n")
        {
            SharedReference.shared.rsyncversionshort = rsyncversionshort
            SharedReference.shared.rsyncversionstring = rsyncversionstring
            self.rsyncversionshort = rsyncversionshort
            self.rsyncversionstring = rsyncversionstring
            updateRsyncVersionStringDelegate?.updatersyncversionstring(rsyncversion: rsyncversionshort)
        }
    }

    func filehandler() {}
}
