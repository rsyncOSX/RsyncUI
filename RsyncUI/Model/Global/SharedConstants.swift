//
//  SharedConstants.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 29/03/2025.
//

// Sendable
struct SharedConstants: Sendable {
    // JSON names
    let filenamelogrecordsjson = "logrecords.json"
    let fileconfigurationsjson = "configurations.json"
    // File quickfile
    let filenamequicktaskjson = "quicktask.json"
    // Caldenarfile
    let caldenarfilejson: String = "calendar.json"
    // Filename logfile
    let logname: String = "rsyncui.txt"
    // filsize logfile warning
    // 1_000_000 Bytes = 1 MB
    let logfilesize: Int = 1_000_000
}
