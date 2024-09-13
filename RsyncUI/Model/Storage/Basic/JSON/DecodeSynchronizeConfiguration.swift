//
//  DecodeSynchronizeConfiguration.swift
//  RsyncOSX
//
//  Created by Thomas Evensen on 17/10/2020.
//  Copyright © 2020 Thomas Evensen. All rights reserved.
//

import Foundation

struct DecodeSynchronizeConfiguration: Codable {
    let backupID: String?
    let dateRun: String?
    let hiddenID: Int?
    let localCatalog: String?
    let offsiteCatalog: String?
    let offsiteServer: String?
    let offsiteUsername: String?
    let parameter1: String?
    let parameter10: String?
    let parameter11: String?
    let parameter12: String?
    let parameter13: String?
    let parameter14: String?
    let parameter2: String?
    let parameter3: String?
    let parameter4: String?
    let parameter8: String?
    let parameter9: String?
    let rsyncdaemon: Int?
    let sshkeypathandidentityfile: String?
    let sshport: Int?
    let task: String?
    let snapdayoffweek: String?
    let snaplast: Int?
    let snapshotnum: Int?

    enum CodingKeys: String, CodingKey {
        case backupID
        case dateRun
        case hiddenID
        case localCatalog
        case offsiteCatalog
        case offsiteServer
        case offsiteUsername
        case parameter1
        case parameter10
        case parameter11
        case parameter12
        case parameter13
        case parameter14
        case parameter2
        case parameter3
        case parameter4
        case parameter8
        case parameter9
        case rsyncdaemon
        case sshkeypathandidentityfile
        case sshport
        case task
        case snapdayoffweek
        case snaplast
        case snapshotnum
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        backupID = try values.decodeIfPresent(String.self, forKey: .backupID)
        dateRun = try values.decodeIfPresent(String.self, forKey: .dateRun)
        hiddenID = try values.decodeIfPresent(Int.self, forKey: .hiddenID)
        localCatalog = try values.decodeIfPresent(String.self, forKey: .localCatalog)
        offsiteCatalog = try values.decodeIfPresent(String.self, forKey: .offsiteCatalog)
        offsiteServer = try values.decodeIfPresent(String.self, forKey: .offsiteServer)
        offsiteUsername = try values.decodeIfPresent(String.self, forKey: .offsiteUsername)
        parameter1 = try values.decodeIfPresent(String.self, forKey: .parameter1)
        parameter10 = try values.decodeIfPresent(String.self, forKey: .parameter10)
        parameter11 = try values.decodeIfPresent(String.self, forKey: .parameter11)
        parameter12 = try values.decodeIfPresent(String.self, forKey: .parameter12)
        parameter13 = try values.decodeIfPresent(String.self, forKey: .parameter13)
        parameter14 = try values.decodeIfPresent(String.self, forKey: .parameter14)
        parameter2 = try values.decodeIfPresent(String.self, forKey: .parameter2)
        parameter3 = try values.decodeIfPresent(String.self, forKey: .parameter3)
        parameter4 = try values.decodeIfPresent(String.self, forKey: .parameter4)
        parameter8 = try values.decodeIfPresent(String.self, forKey: .parameter8)
        parameter9 = try values.decodeIfPresent(String.self, forKey: .parameter9)
        rsyncdaemon = try values.decodeIfPresent(Int.self, forKey: .rsyncdaemon)
        sshkeypathandidentityfile = try values.decodeIfPresent(String.self, forKey: .sshkeypathandidentityfile)
        sshport = try values.decodeIfPresent(Int.self, forKey: .sshport)
        task = try values.decodeIfPresent(String.self, forKey: .task)
        snapdayoffweek = try values.decodeIfPresent(String.self, forKey: .snapdayoffweek)
        snaplast = try values.decodeIfPresent(Int.self, forKey: .snaplast)
        snapshotnum = try values.decodeIfPresent(Int.self, forKey: .snapshotnum)
    }
}
