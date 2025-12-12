//
//  UserConfiguration.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 12/02/2022.
//

import Foundation

@MainActor
struct UserConfiguration: @MainActor Codable {
    var rsyncversion3: Int = -1
    // Detailed logging
    var addsummarylogrecord: Int = 1
    // local path for rsync
    var localrsyncpath: String?
    // temporary path for restore
    var pathforrestore: String?
    // days for mark days since last synchronize
    var marknumberofdayssince: String = "5"
    // Global ssh keypath and port
    var sshkeypathandidentityfile: String?
    var sshport: Int?
    // Environment variable
    var environment: String?
    var environmentvalue: String?
    // Check for error in output from rsync
    var checkforerrorinrsyncoutput: Int = -1
    // Automatic execution
    var confirmexecute: Int?
    // Timedelay Syncjronize URL-actions
    var synchronizewithouttimedelay: Int = -1
    // Hide or show the Sidebar on startup
    var sidebarishidden: Int = -1
    // Observe mounting local atteched discs
    var observemountedvolumes: Int = -1
    // Always show the summarized estimate view
    var alwaysshowestimateddetailsview: Int = -1
    // Hide Verify View
    var hideverifyremotefunction: Int = -1
    // Silence missing stats
    var silencemissingstats: Int = -1

    private func intToBool(_ value: Int) -> Bool {
        value == 1
    }

    private func boolToInt(_ value: Bool) -> Int {
        value ? 1 : -1
    }

    private func setuserconfigdata() {
        SharedReference.shared.rsyncversion3 = intToBool(rsyncversion3)
        SharedReference.shared.addsummarylogrecord = intToBool(addsummarylogrecord)
        SharedReference.shared.localrsyncpath = localrsyncpath
        SharedReference.shared.pathforrestore = pathforrestore
        if Int(marknumberofdayssince) ?? 0 > 0 {
            SharedReference.shared.marknumberofdayssince = Int(marknumberofdayssince) ?? 0
        }
        SharedReference.shared.sshkeypathandidentityfile = sshkeypathandidentityfile
        SharedReference.shared.sshport = sshport
        SharedReference.shared.environment = environment
        SharedReference.shared.environmentvalue = environmentvalue
        SharedReference.shared.checkforerrorinrsyncoutput = intToBool(checkforerrorinrsyncoutput)
        if let confirmexecute {
            SharedReference.shared.confirmexecute = intToBool(confirmexecute)
        } else {
            SharedReference.shared.confirmexecute = false
        }
        SharedReference.shared.synchronizewithouttimedelay = intToBool(synchronizewithouttimedelay)
        SharedReference.shared.sidebarishidden = intToBool(sidebarishidden)
        SharedReference.shared.observemountedvolumes = intToBool(observemountedvolumes)
        SharedReference.shared.alwaysshowestimateddetailsview = intToBool(alwaysshowestimateddetailsview)
        SharedReference.shared.hideverifyremotefunction = intToBool(hideverifyremotefunction)
        SharedReference.shared.silencemissingstats = intToBool(silencemissingstats)
    }

    // Used when reading JSON data from store
    @discardableResult
    init(_ data: DecodeUserConfiguration) {
        rsyncversion3 = data.rsyncversion3 ?? -1
        addsummarylogrecord = data.addsummarylogrecord ?? 1
        localrsyncpath = data.localrsyncpath
        pathforrestore = data.pathforrestore
        marknumberofdayssince = data.marknumberofdayssince ?? "5"
        sshkeypathandidentityfile = data.sshkeypathandidentityfile
        sshport = data.sshport
        environment = data.environment
        environmentvalue = data.environmentvalue
        checkforerrorinrsyncoutput = data.checkforerrorinrsyncoutput ?? -1
        confirmexecute = data.confirmexecute ?? -1
        synchronizewithouttimedelay = data.synchronizewithouttimedelay ?? -1
        sidebarishidden = data.sidebarishidden ?? -1
        observemountedvolumes = data.observemountedvolumes ?? -1
        alwaysshowestimateddetailsview = data.alwaysshowestimateddetailsview ?? -1
        hideverifyremotefunction = data.hideverifyremotefunction ?? -1
        silencemissingstats = data.silencemissingstats ?? -1
        setuserconfigdata()
    }

    // Default values user configuration
    @discardableResult
    init() {
        rsyncversion3 = boolToInt(SharedReference.shared.rsyncversion3)
        addsummarylogrecord = boolToInt(SharedReference.shared.addsummarylogrecord)
        localrsyncpath = SharedReference.shared.localrsyncpath
        pathforrestore = SharedReference.shared.pathforrestore
        marknumberofdayssince = String(SharedReference.shared.marknumberofdayssince)
        sshkeypathandidentityfile = SharedReference.shared.sshkeypathandidentityfile
        sshport = SharedReference.shared.sshport
        environment = SharedReference.shared.environment
        environmentvalue = SharedReference.shared.environmentvalue
        checkforerrorinrsyncoutput = boolToInt(SharedReference.shared.checkforerrorinrsyncoutput)
        confirmexecute = boolToInt(SharedReference.shared.confirmexecute)
        synchronizewithouttimedelay = boolToInt(SharedReference.shared.synchronizewithouttimedelay)
        sidebarishidden = boolToInt(SharedReference.shared.sidebarishidden)
        observemountedvolumes = boolToInt(SharedReference.shared.observemountedvolumes)
        alwaysshowestimateddetailsview = boolToInt(SharedReference.shared.alwaysshowestimateddetailsview)
        hideverifyremotefunction = boolToInt(SharedReference.shared.hideverifyremotefunction)
        silencemissingstats = boolToInt(SharedReference.shared.silencemissingstats)
    }
}
