//
//  DecodeConfiguration.swift
//  RsyncOSX
//
//  Created by Thomas Evensen on 17/10/2020.
//  Copyright © 2020 Thomas Evensen. All rights reserved.
//
//	Model file generated using JSONExport: https://github.com/Ahmed-Ali/JSONExport

import Foundation

struct DecodeConfiguration: Codable {
    let backupID: String?
    let dateRun: String?
    let haltshelltasksonerror: Int?
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
    let parameter5: String?
    let parameter6: String?
    let parameter8: String?
    let parameter9: String?
    let rsyncdaemon: Int?
    let sshkeypathandidentityfile: String?
    let sshport: Int?
    let task: String?
    let snapdayoffweek: String?
    let snaplast: Int?
    let executepretask: Int?
    let pretask: String?
    let executeposttask: Int?
    let posttask: String?
    let snapshotnum: Int?

    enum CodingKeys: String, CodingKey {
        case backupID
        case dateRun
        case haltshelltasksonerror
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
        case parameter5
        case parameter6
        case parameter8
        case parameter9
        case rsyncdaemon
        case sshkeypathandidentityfile
        case sshport
        case task
        case snapdayoffweek
        case snaplast
        case executepretask
        case pretask
        case executeposttask
        case posttask
        case snapshotnum
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        backupID = try values.decodeIfPresent(String.self, forKey: .backupID)
        dateRun = try values.decodeIfPresent(String.self, forKey: .dateRun)
        haltshelltasksonerror = try values.decodeIfPresent(Int.self, forKey: .haltshelltasksonerror)
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
        parameter5 = try values.decodeIfPresent(String.self, forKey: .parameter5)
        parameter6 = try values.decodeIfPresent(String.self, forKey: .parameter6)
        parameter8 = try values.decodeIfPresent(String.self, forKey: .parameter8)
        parameter9 = try values.decodeIfPresent(String.self, forKey: .parameter9)
        rsyncdaemon = try values.decodeIfPresent(Int.self, forKey: .rsyncdaemon)
        sshkeypathandidentityfile = try values.decodeIfPresent(String.self, forKey: .sshkeypathandidentityfile)
        sshport = try values.decodeIfPresent(Int.self, forKey: .sshport)
        task = try values.decodeIfPresent(String.self, forKey: .task)
        snapdayoffweek = try values.decodeIfPresent(String.self, forKey: .snapdayoffweek)
        snaplast = try values.decodeIfPresent(Int.self, forKey: .snaplast)
        executepretask = try values.decodeIfPresent(Int.self, forKey: .executepretask)
        pretask = try values.decodeIfPresent(String.self, forKey: .pretask)
        executeposttask = try values.decodeIfPresent(Int.self, forKey: .executeposttask)
        posttask = try values.decodeIfPresent(String.self, forKey: .posttask)
        snapshotnum = try values.decodeIfPresent(Int.self, forKey: .snapshotnum)
    }

    // This init is used in WriteConfigurationJSON
    init(_ data: SynchronizeConfiguration) {
        backupID = data.backupID
        dateRun = data.dateRun
        haltshelltasksonerror = data.haltshelltasksonerror
        hiddenID = data.hiddenID
        localCatalog = data.localCatalog
        offsiteCatalog = data.offsiteCatalog
        offsiteServer = data.offsiteServer
        offsiteUsername = data.offsiteUsername
        parameter1 = data.parameter1
        parameter10 = data.parameter10
        parameter11 = data.parameter11
        parameter12 = data.parameter12
        parameter13 = data.parameter13
        parameter14 = data.parameter14
        parameter2 = data.parameter2
        parameter3 = data.parameter3
        parameter4 = data.parameter4
        parameter5 = data.parameter5
        parameter6 = data.parameter6
        parameter8 = data.parameter8
        parameter9 = data.parameter9
        rsyncdaemon = data.rsyncdaemon
        sshkeypathandidentityfile = data.sshkeypathandidentityfile
        sshport = data.sshport
        task = data.task
        snapdayoffweek = data.snapdayoffweek
        snaplast = data.snaplast
        executepretask = data.executepretask
        pretask = data.pretask
        executeposttask = data.executeposttask
        posttask = data.posttask
        snapshotnum = data.snapshotnum
    }
}
