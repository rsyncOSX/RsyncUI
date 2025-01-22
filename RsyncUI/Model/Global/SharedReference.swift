//
//  SharedReference.swift
//  RsyncOSX
//
//  Created by Thomas Evensen on 05.09.2017.
//  Copyright © 2017 Thomas Evensen. All rights reserved.
//

import Foundation
import Observation

@Observable
final class SharedReference {
    @MainActor static let shared = SharedReference()

    private init() {}

    // Version 3.x of rsync
    @ObservationIgnored var rsyncversion3: Bool = false
    // Optional path to rsync
    @ObservationIgnored var localrsyncpath: String?
    // No valid rsyncPath - true if no valid rsync is found
    @ObservationIgnored var norsync: Bool = false
    // Path for restore
    @ObservationIgnored var pathforrestore: String?
    // Add summary to logrecords
    @ObservationIgnored var addsummarylogrecord: Bool = true
    // Mark number of days since last backup
    @ObservationIgnored var marknumberofdayssince: Int = 5
    @ObservationIgnored var environment: String?
    @ObservationIgnored var environmentvalue: String?
    // Global SSH parameters
    @ObservationIgnored var sshport: Int?
    @ObservationIgnored var sshkeypathandidentityfile: String?
    // Check for error in output from rsync
    @ObservationIgnored var checkforerrorinrsyncoutput: Bool = false
    // Check for network changes
    @ObservationIgnored var monitornetworkconnection: Bool = false
    // Confirm execution
    // A safety rule
    @ObservationIgnored var confirmexecute: Bool = false
    // Duplicatecheck
    @ObservationIgnored var duplicatecheck: Bool = true
    // New version of RsyncUI discovered
    @ObservationIgnored var newversion: Bool = false
    // Synchronize without timedelay URL-actions
    @ObservationIgnored var synchronizewithouttimedelay: Bool = false
    // rsync command
    let rsync: String = "rsync"
    let usrbin: String = "/usr/bin"
    let usrlocalbin: String = "/usr/local/bin"
    let usrlocalbinarm: String = "/opt/homebrew/bin"
    @ObservationIgnored var macosarm: Bool = false
    // RsyncUI config files and path
    let configpath: String = "/.rsyncosx/"
    let logname: String = "rsyncui.txt"
    // Userconfiguration json file
    let userconfigjson: String = "rsyncuiconfig.json"
    // String tasks
    let synchronize: String = "synchronize"
    let snapshot: String = "snapshot"
    let syncremote: String = "syncremote"
    // rsync short version
    var rsyncversionshort: String?
    // filsize logfile warning
    // 1_000_000 Bytes = 1 MB
    let logfilesize: Int = 1_000_000
    // Mac serialnumer
    @ObservationIgnored var macserialnumber: String?
    // Reference to the active process
    var process: Process?
    // JSON names
    let filenamelogrecordsjson = "logrecords.json"
    let fileconfigurationsjson = "configurations.json"
    // Object for propogate errors to views
    @ObservationIgnored var errorobject: AlertError?
    // Used when starting up RsyncUI
    // Default profile
    let defaultprofile = "Default profile"
    // let bundleIdentifier: String = "no.blogspot.RsyncUI"
    @ObservationIgnored var sidebarishidden: Bool = true
}
