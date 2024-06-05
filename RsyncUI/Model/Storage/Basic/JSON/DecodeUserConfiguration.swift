//
//  DecodeUserConfiguration.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 12/02/2022.
//

import Foundation

struct DecodeUserConfiguration: Codable {
    let rsyncversion3: Int?
    // Detailed logging
    let addsummarylogrecord: Int?
    // Logging to logfile
    let logtofile: Int?
    // Monitor network connection
    let monitornetworkconnection: Int?
    // local path for rsync
    let localrsyncpath: String?
    // temporary path for restore
    let pathforrestore: String?
    // days for mark days since last synchronize
    let marknumberofdayssince: String?
    // Global ssh keypath and port
    let sshkeypathandidentityfile: String?
    let sshport: Int?
    // Environment variable
    let environment: String?
    let environmentvalue: String?
    let checkforerrorinrsyncoutput: Int?
    // Confirm execute
    let confirmexecute: Int?

    enum CodingKeys: String, CodingKey {
        case rsyncversion3
        case addsummarylogrecord
        case logtofile
        case monitornetworkconnection
        case localrsyncpath
        case pathforrestore
        case marknumberofdayssince
        case sshkeypathandidentityfile
        case sshport
        case environment
        case environmentvalue
        case checkforerrorinrsyncoutput
        case confirmexecute
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        rsyncversion3 = try values.decodeIfPresent(Int.self, forKey: .rsyncversion3)
        addsummarylogrecord = try values.decodeIfPresent(Int.self, forKey: .addsummarylogrecord)
        logtofile = try values.decodeIfPresent(Int.self, forKey: .logtofile)
        monitornetworkconnection = try values.decodeIfPresent(Int.self, forKey: .monitornetworkconnection)
        localrsyncpath = try values.decodeIfPresent(String.self, forKey: .localrsyncpath)
        pathforrestore = try values.decodeIfPresent(String.self, forKey: .pathforrestore)
        marknumberofdayssince = try values.decodeIfPresent(String.self, forKey: .marknumberofdayssince)
        sshkeypathandidentityfile = try values.decodeIfPresent(String.self, forKey: .sshkeypathandidentityfile)
        sshport = try values.decodeIfPresent(Int.self, forKey: .sshport)
        environment = try values.decodeIfPresent(String.self, forKey: .environment)
        environmentvalue = try values.decodeIfPresent(String.self, forKey: .environmentvalue)
        checkforerrorinrsyncoutput = try values.decodeIfPresent(Int.self, forKey: .checkforerrorinrsyncoutput)
        confirmexecute = try values.decodeIfPresent(Int.self, forKey: .confirmexecute)
    }

    init(_ userconfiguration: UserConfiguration) {
        rsyncversion3 = userconfiguration.rsyncversion3
        addsummarylogrecord = userconfiguration.addsummarylogrecord
        logtofile = userconfiguration.logtofile
        monitornetworkconnection = userconfiguration.monitornetworkconnection
        localrsyncpath = userconfiguration.localrsyncpath
        pathforrestore = userconfiguration.pathforrestore
        marknumberofdayssince = userconfiguration.marknumberofdayssince
        sshkeypathandidentityfile = userconfiguration.sshkeypathandidentityfile
        sshport = userconfiguration.sshport
        environment = userconfiguration.environment
        environmentvalue = userconfiguration.environmentvalue
        checkforerrorinrsyncoutput = userconfiguration.checkforerrorinrsyncoutput
        confirmexecute = userconfiguration.confirmexecute
    }
}
