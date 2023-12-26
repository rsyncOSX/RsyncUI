//
//  SharedReference.swift
//  RsyncOSX
//
//  Created by Thomas Evensen on 05.09.2017.
//  Copyright © 2017 Thomas Evensen. All rights reserved.
//

import Foundation

class SharedReference {
    // Creates a singelton of this class
    class var shared: SharedReference {
        struct Singleton {
            static let instance = SharedReference()
        }
        return Singleton.instance
    }

    var rsyncversion3: Bool = false
    // Optional path to rsync
    var localrsyncpath: String?
    // No valid rsyncPath - true if no valid rsync is found
    var norsync: Bool = false
    // Path for restore
    var pathforrestore: String?
    // Detailed logging
    var detailedlogging: Bool = true
    // Logging to logfile
    var minimumlogging: Bool = false
    var fulllogging: Bool = false
    var nologging: Bool = true
    // Set to here
    // Mark number of days since last backup
    var marknumberofdayssince: Int = 5
    var environment: String?
    var environmentvalue: String?
    // Halt on error
    // var haltonerror: Bool = false
    // Global SSH parameters
    var sshport: Int?
    var sshkeypathandidentityfile: String?
    // Check for error in output from rsync
    var checkforerrorinrsyncoutput: Bool = false
    // Check for network changes
    var monitornetworkconnection: Bool = false
    // Download URL if new version is avaliable
    var URLnewVersion: String?
    // rsync command
    let rsync: String = "rsync"
    let usrbin: String = "/usr/bin"
    let usrlocalbin: String = "/usr/local/bin"
    let usrlocalbinarm: String = "/opt/homebrew/bin"
    var macosarm: Bool = false
    // RsyncUI config files and path
    let configpath: String = "/.rsyncosx/"
    let logname: String = "rsyncui.txt"
    // Userconfiguration json file
    let userconfigjson: String = "rsyncuiconfig.json"
    // String tasks
    let synchronize: String = "synchronize"
    let snapshot: String = "snapshot"
    let syncremote: String = "syncremote"
    var synctasks: Set<String>
    // rsync version string
    var rsyncversionstring: String?
    // rsync short version
    var rsyncversionshort: String?
    // filsize logfile warning
    var logfilesize: Int = 100_000
    // Mac serialnumer
    var macserialnumber: String?
    // True if menuapp is running
    // var menuappisrunning: Bool = false
    // Reference to the active process
    var process: Process?
    // JSON names
    let fileschedulesjson = "schedules.json"
    let fileconfigurationsjson = "configurations.json"
    // Object for propogate errors to views
    var errorobject: AlertError?
    // Used when starting up RsyncUI
    // var reload: Bool = true
    // Default profile
    let defaultprofile = "Default profile"
    // If firstime use
    var firsttime = false
    // Confirm execution
    // A safety rule
    var confirmexecute: Bool = true

    private init() {
        synctasks = Set<String>()
        synctasks = [synchronize, snapshot, syncremote]
    }
}
