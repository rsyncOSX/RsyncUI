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
    let detailedlogging: Int?
    // Logging to logfile
    let minimumlogging: Int?
    let fulllogging: Int?
    let nologging: Int?
    // Monitor network connection
    let monitornetworkconnection: Int?
    // local path for rsync
    let localrsyncpath: String?
    // temporary path for restore
    let pathforrestore: String?
    // days for mark days since last synchronize
    let marknumberofdayssince: String?

    enum CodingKeys: String, CodingKey {
        case rsyncversion3
        case detailedlogging
        case minimumlogging
        case fulllogging
        case nologging
        case monitornetworkconnection
        case localrsyncpath
        case pathforrestore
        case marknumberofdayssince
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        rsyncversion3 = try values.decodeIfPresent(Int.self, forKey: .rsyncversion3)
        detailedlogging = try values.decodeIfPresent(Int.self, forKey: .detailedlogging)
        minimumlogging = try values.decodeIfPresent(Int.self, forKey: .minimumlogging)
        fulllogging = try values.decodeIfPresent(Int.self, forKey: .fulllogging)
        nologging = try values.decodeIfPresent(Int.self, forKey: .nologging)
        monitornetworkconnection = try values.decodeIfPresent(Int.self, forKey: .monitornetworkconnection)
        localrsyncpath = try values.decodeIfPresent(String.self, forKey: .localrsyncpath)
        pathforrestore = try values.decodeIfPresent(String.self, forKey: .pathforrestore)
        marknumberofdayssince = try values.decodeIfPresent(String.self, forKey: .marknumberofdayssince)
    }

    init(_ userconfiguration: UserConfiguration) {
        rsyncversion3 = userconfiguration.rsyncversion3
        detailedlogging = userconfiguration.detailedlogging
        minimumlogging = userconfiguration.minimumlogging
        fulllogging = userconfiguration.fulllogging
        nologging = userconfiguration.nologging
        monitornetworkconnection = userconfiguration.monitornetworkconnection
        localrsyncpath = userconfiguration.localrsyncpath
        pathforrestore = userconfiguration.pathforrestore
        marknumberofdayssince = userconfiguration.marknumberofdayssince
    }
}
