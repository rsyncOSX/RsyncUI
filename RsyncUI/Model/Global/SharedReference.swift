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

    // Set true when usersettings are loaded from permanent store
    var inloading: Bool = false
    // True if version 3.1.2 or 3.1.3 of rsync in /usr/local/bin
    var rsyncversion3: Bool = false
    // Optional path to rsync
    var localrsyncpath: String?
    // No valid rsyncPath - true if no valid rsync is found
    var norsync: Bool = false
    // Temporary path for restore
    var pathforrestore: String?
    // Detailed logging
    var detailedlogging: Bool = true
    // Logging to logfile
    var minimumlogging: Bool = false
    var fulllogging: Bool = false
    var nologging: Bool = true
    // Set to here
    // Mark number of days since last backup
    var marknumberofdayssince: Double = 5
    var environment: String?
    var environmentvalue: String?
    // Halt on error
    // var haltonerror: Bool = false
    // Global SSH parameters
    var sshport: Int?
    var sshkeypathandidentityfile: String?
    // Check input when loading schedules and adding config
    var checkinput: Bool = false
    // Check for network changes
    var monitornetworkconnection: Bool = false
    // Read configurations and schedules as JSON or not
    var json: Bool = false
    // Download URL if new version is avaliable
    var URLnewVersion: String?
    // rsync command
    var rsync: String = "rsync"
    var usrbin: String = "/usr/bin"
    var usrlocalbin: String = "/usr/local/bin"
    // Where RsyncOSX config files are stored
    var configpath: String = "/Rsync/"
    // New RsynOSX config files and path
    var newconfigpath: String = "/.rsyncosx/"
    var usenewconfigpath: Bool = true
    // Plistnames and key
    var scheduleplist: String = "/scheduleRsync.plist"
    var schedulekey: String = "Schedule"
    var configurationsplist: String = "/configRsync.plist"
    var configurationskey: String = "Catalogs"
    var userconfigplist: String = "/config.plist"
    var userconfigkey: String = "config"
    var logname: String = "rsynclog.txt"
    // String tasks
    var synchronize: String = "synchronize"
    var snapshot: String = "snapshot"
    var syncremote: String = "syncremote"
    var synctasks: Set<String>
    // rsync version string
    var rsyncversionstring: String?
    // rsync short version
    var rsyncversionshort: String?
    // filsize logfile warning
    var logfilesize: Int = 100_000
    // Paths
    var pathrsyncosx: String?
    var pathrsyncosxsched: String?
    var namersyncosx = "RsyncOSX.app"
    var namersyncosssched = "RsyncOSXsched.app"
    // Mac serialnumer
    var macserialnumber: String?
    // True if menuapp is running
    var menuappisrunning: Bool = false
    // Reference to the active process
    var process: Process?
    // JSON names
    var fileschedulesjson = "schedules.json"
    var fileconfigurationsjson = "configurations.json"
    // Object for propogate errors to views
    var errorobject: ErrorHandling?

    init() {
        synctasks = Set<String>()
        synctasks = [synchronize, snapshot, syncremote]
    }
}

// These has to be cleaned up, only a few used.
enum DictionaryStrings: String {
    case localCatalog
    case profile
    case remoteCatalog
    case offsiteServer
    case task
    case backupID
    case dateExecuted
    case offsiteUsername
    case markdays
    case hiddenID
    case offsiteCatalog
    case dateStart
    case schedule
    case dateStop
    case resultExecuted
    case snapshotnum
    case snapdayoffweek
    case dateRun
    case executepretask
    case executeposttask
    case snap
    case runDate
    case haltshelltasksonerror
    case parameter1
    case parameter2
    case parameter3
    case parameter4
    case parameter5
    case parameter6
    case parameter8
    case parameter9
    case parameter10
    case parameter11
    case parameter12
    case parameter13
    case parameter14
    case rsyncdaemon
    case sshport
    case snaplast
    case sshkeypathandidentityfile
    case pretask
    case posttask
    case executed
    case offsiteserver
    case version3Rsync
    case detailedlogging
    case rsyncPath
    case restorePath
    case marknumberofdayssince
    case pathrsyncosx
    case pathrsyncosxsched
    case minimumlogging
    case fulllogging
    case environment
    case environmentvalue
    case haltonerror
    case monitornetworkconnection
    case json
    case used
    case avail
    case availpercent
    case remotecomputers
    case remoteusers
    case remotehome
    case catalogs
    case localhome
    case transferredNumber
    case sibling
    case parent
    case timetostart
    case start
    case snapshotCatalog
    case days
    case totalNumber
    case totalDirs
    case transferredNumberSizebytes
    case totalNumberSizebytes
    case newfiles
    case deletefiles
    case select
    case startsin
    case delta
    case profilename
    case index
    case localhost
    case period
}
