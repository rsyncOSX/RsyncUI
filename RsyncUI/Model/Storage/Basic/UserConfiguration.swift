//
//  UserConfiguration.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 12/02/2022.
//

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
            validatepathforrsync(localrsyncpath ?? "")
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
    }

    func validatepathforrsync(_ path: String) {
        let validate = SetandValidatepathforrsync()
        validate.setlocalrsyncpath(path)
        do {
            let ok = try validate.validateandrsyncpath()
            if ok { return }
        } catch let e {
            let error = e
            propogateerror(error: error)
        }
    }

    func propogateerror(error: Error) {
        SharedReference.shared.errorobject?.propogateerror(error: error)
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
        // Set user configdata read from permanent store
        setuserconfigdata()
    }

    // Default values user configuration
    @discardableResult
    init(_ save: Bool) {
        if save {
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
                validatepathforrsync(localrsyncpath ?? "")
            } else {
                localrsyncpath = nil
            }
            if SharedReference.shared.pathforrestore != nil {
                pathforrestore = SharedReference.shared.pathforrestore
            } else {
                pathforrestore = nil
            }
            marknumberofdayssince = String(SharedReference.shared.marknumberofdayssince)
        }
    }
}
