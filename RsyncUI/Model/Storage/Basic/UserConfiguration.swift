//
//  UserConfiguration.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 12/02/2022.
//
// swiftlint:disable cyclomatic_complexity function_body_length

import Foundation

struct UserConfiguration: Codable {
    var rsyncversion3: Int = -1
    // Detailed logging
    var detailedlogging: Int = 1
    // Logging to logfile
    var minimumlogging: Int = -1
    var fulllogging: Int = -1
    var nologging: Int = 1
    // Montor network connection
    var monitornetworkconnection: Int = -1
    // local path for rsync
    var localrsyncpath: String?
    // temporary path for restore
    var pathforrestore: String?
    // days for mark days since last synchronize
    var marknumberofdayssince: String = "5.0"
    // Global ssh keypath and port
    var sshkeypathandidentityfile: String?
    var sshport: Int?
    // Environment variable
    var environment: String?
    var environmentvalue: String?
    // Check for error in output from rsync
    var checkforerrorinrsyncoutput: Int = -1

    private func setuserconfigdata() {
        if rsyncversion3 == 1 {
            SharedReference.shared.rsyncversion3 = true
        } else {
            SharedReference.shared.rsyncversion3 = false
        }
        if detailedlogging == 1 {
            SharedReference.shared.detailedlogging = true
        } else {
            SharedReference.shared.detailedlogging = false
        }
        if minimumlogging == 1 {
            SharedReference.shared.minimumlogging = true
        } else {
            SharedReference.shared.minimumlogging = false
        }
        if fulllogging == 1 {
            SharedReference.shared.fulllogging = true
        } else {
            SharedReference.shared.fulllogging = false
        }
        if nologging == 1 {
            SharedReference.shared.nologging = true
        } else {
            SharedReference.shared.nologging = false
        }
        if monitornetworkconnection == 1 {
            SharedReference.shared.monitornetworkconnection = true
        } else {
            SharedReference.shared.monitornetworkconnection = false
        }
        if localrsyncpath != nil {
            SharedReference.shared.localrsyncpath = localrsyncpath
        } else {
            SharedReference.shared.localrsyncpath = nil
        }
        if pathforrestore != nil {
            SharedReference.shared.pathforrestore = pathforrestore
        } else {
            SharedReference.shared.pathforrestore = nil
        }
        if Double(marknumberofdayssince) ?? 0 > 0 {
            SharedReference.shared.marknumberofdayssince = Double(marknumberofdayssince)!
        }
        if sshkeypathandidentityfile != nil {
            SharedReference.shared.sshkeypathandidentityfile = sshkeypathandidentityfile
        }
        if sshport != nil {
            SharedReference.shared.sshport = sshport
        }
        if environment != nil {
            SharedReference.shared.environment = environment
        }
        if environmentvalue != nil {
            SharedReference.shared.environmentvalue = environmentvalue
        }
        if checkforerrorinrsyncoutput == 1 {
            SharedReference.shared.checkforerrorinrsyncoutput = true
        } else {
            SharedReference.shared.checkforerrorinrsyncoutput = false
        }
    }

    // Used when reading JSON data from store
    @discardableResult
    init(_ data: DecodeUserConfiguration) {
        rsyncversion3 = data.rsyncversion3 ?? -1
        detailedlogging = data.detailedlogging ?? 1
        minimumlogging = data.minimumlogging ?? -1
        fulllogging = data.fulllogging ?? -1
        nologging = data.nologging ?? 1
        monitornetworkconnection = data.monitornetworkconnection ?? -1
        localrsyncpath = data.localrsyncpath
        pathforrestore = data.pathforrestore
        marknumberofdayssince = data.marknumberofdayssince ?? "5.0"
        sshkeypathandidentityfile = data.sshkeypathandidentityfile
        sshport = data.sshport
        environment = data.environment
        environmentvalue = data.environmentvalue
        // Set user configdata read from permanent store
        checkforerrorinrsyncoutput = data.checkforerrorinrsyncoutput ?? -1
        setuserconfigdata()
    }

    // Default values user configuration
    @discardableResult
    init() {
        if SharedReference.shared.rsyncversion3 {
            rsyncversion3 = 1
        } else {
            rsyncversion3 = -1
        }
        if SharedReference.shared.detailedlogging {
            detailedlogging = 1
        } else {
            detailedlogging = -1
        }
        if SharedReference.shared.minimumlogging {
            minimumlogging = 1
        } else {
            minimumlogging = -1
        }
        if SharedReference.shared.fulllogging {
            fulllogging = 1
        } else {
            fulllogging = -1
        }
        if SharedReference.shared.nologging {
            nologging = 1
        } else {
            nologging = -1
        }
        if SharedReference.shared.monitornetworkconnection {
            monitornetworkconnection = 1
        } else {
            monitornetworkconnection = -1
        }
        if SharedReference.shared.localrsyncpath != nil {
            localrsyncpath = SharedReference.shared.localrsyncpath
        } else {
            localrsyncpath = nil
        }
        if SharedReference.shared.pathforrestore != nil {
            pathforrestore = SharedReference.shared.pathforrestore
        } else {
            pathforrestore = nil
        }
        marknumberofdayssince = String(SharedReference.shared.marknumberofdayssince)
        if SharedReference.shared.sshkeypathandidentityfile != nil {
            sshkeypathandidentityfile = SharedReference.shared.sshkeypathandidentityfile
        }
        if SharedReference.shared.sshport != nil {
            sshport = SharedReference.shared.sshport
        }
        if SharedReference.shared.environment != nil {
            environment = SharedReference.shared.environment
        }
        if SharedReference.shared.environmentvalue != nil {
            environmentvalue = SharedReference.shared.environmentvalue
        }
        if SharedReference.shared.checkforerrorinrsyncoutput == true {
            checkforerrorinrsyncoutput = 1
        } else {
            checkforerrorinrsyncoutput = -1
        }
    }
}

// swiftlint:enable cyclomatic_complexity function_body_length
