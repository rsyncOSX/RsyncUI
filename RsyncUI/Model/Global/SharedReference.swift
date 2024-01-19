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

    var settingsischanged: Bool = false
    var rsyncversion3: Bool = false {
        didSet {
            settingsischanged = true
        }
    }

    // Optional path to rsync
    var localrsyncpath: String? {
        didSet {
            settingsischanged = true
        }
    }

    // No valid rsyncPath - true if no valid rsync is found
    var norsync: Bool = false
    // Path for restore
    var pathforrestore: String? {
        didSet {
            settingsischanged = true
        }
    }

    // Detailed logging
    var detailedlogging: Bool = true {
        didSet {
            settingsischanged = true
        }
    }

    // Logging to logfile
    var minimumlogging: Bool = false {
        didSet {
            settingsischanged = true
        }
    }

    var fulllogging: Bool = false {
        didSet {
            settingsischanged = true
        }
    }

    var nologging: Bool = true {
        didSet {
            settingsischanged = true
        }
    }

    // Set to here
    // Mark number of days since last backup
    var marknumberofdayssince: Int = 5 {
        didSet {
            settingsischanged = true
        }
    }

    var environment: String? {
        didSet {
            settingsischanged = true
        }
    }

    var environmentvalue: String? {
        didSet {
            settingsischanged = true
        }
    }

    // Halt on error
    // var haltonerror: Bool = false
    // Global SSH parameters
    var sshport: Int? {
        didSet {
            settingsischanged = true
        }
    }

    var sshkeypathandidentityfile: String? {
        didSet {
            settingsischanged = true
        }
    }

    // Check for error in output from rsync
    var checkforerrorinrsyncoutput: Bool = false {
        didSet {
            settingsischanged = true
        }
    }

    // Check for network changes
    var monitornetworkconnection: Bool = false {
        didSet {
            settingsischanged = true
        }
    }

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
    let filenamelogrecordsjson = "logrecords.json"
    let fileconfigurationsjson = "configurations.json"
    // Object for propogate errors to views
    var errorobject: AlertError?
    // Used when starting up RsyncUI
    // Default profile
    let defaultprofile = "Default profile"
    // If firstime use
    var firsttime = false
    // Confirm execution
    // A safety rule
    var confirmexecute: Bool = false {
        didSet {
            settingsischanged = true
        }
    }

    // Logfile and convert logfile
    var defaultlogfileexist: Bool = true
    var copydataoldlogfiletonewlogfile: Bool = false

    private init() {
        synctasks = Set<String>()
        synctasks = [synchronize, snapshot, syncremote]
    }
}
