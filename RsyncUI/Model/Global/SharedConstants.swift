//
//  SharedConstants.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 29/03/2025.
//

struct SharedConstants {
    // rsync command
    let rsync: String = "rsync"
    let usrbin: String = "/usr/bin"
    let usrlocalbin: String = "/usr/local/bin"
    let usrlocalbinarm: String = "/opt/homebrew/bin"
    // RsyncUI config files and path
    let configpath: String = "/.rsyncosx/"
    let logname: String = "rsyncui.txt"
    // Userconfiguration json file
    let userconfigjson: String = "rsyncuiconfig.json"
    // Caldenarfile
    let caldenarfilejson: String = "calendar.json"
    // String tasks
    let synchronize: String = "synchronize"
    let snapshot: String = "snapshot"
    let syncremote: String = "syncremote"
    let halted: String = "halted"
    // filsize logfile warning
    // 1_000_000 Bytes = 1 MB
    let logfilesize: Int = 1_000_000
    // JSON names
    let filenamelogrecordsjson = "logrecords.json"
    let fileconfigurationsjson = "configurations.json"
    // Default profile
    let defaultprofile = "Default profile"
    // Value for alert tagging
    let alerttagginglines = 20
}
