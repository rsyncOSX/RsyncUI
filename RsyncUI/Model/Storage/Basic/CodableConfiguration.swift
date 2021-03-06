//
//  ConvertConfigurationsCodable.swift
//  RsyncOSX
//
//  Created by Thomas Evensen on 16/10/2020.
//  Copyright © 2020 Thomas Evensen. All rights reserved.
//
//

import Foundation

struct CodableConfiguration: Codable {
    var hiddenID: Int
    var task: String
    var localCatalog: String
    var offsiteCatalog: String
    var offsiteUsername: String
    var parameter1: String?
    var parameter2: String
    var parameter3: String
    var parameter4: String
    var parameter5: String
    var parameter6: String
    var offsiteServer: String
    var backupID: String
    var dateRun: String?
    var snapshotnum: Int?
    // parameters choosed by user
    var parameter8: String?
    var parameter9: String?
    var parameter10: String?
    var parameter11: String?
    var parameter12: String?
    var parameter13: String?
    var parameter14: String?
    var rsyncdaemon: Int?
    // SSH parameters
    var sshport: Int?
    var sshkeypathandidentityfile: String?
    var profile: String?
    // Snapshots, day to save and last = 1 or every last=0
    var snapdayoffweek: String?
    var snaplast: Int?
    // Pre and post tasks
    var executepretask: Int?
    var pretask: String?
    var executeposttask: Int?
    var posttask: String?
    var haltshelltasksonerror: Int?

    init(config: Configuration?) {
        hiddenID = config?.hiddenID ?? -1
        task = config?.task ?? ""
        localCatalog = config?.localCatalog ?? ""
        offsiteCatalog = config?.offsiteCatalog ?? ""
        offsiteUsername = config?.offsiteUsername ?? ""
        parameter1 = config?.parameter1 ?? ""
        parameter2 = config?.parameter2 ?? ""
        parameter3 = config?.parameter3 ?? ""
        parameter4 = config?.parameter4 ?? ""
        parameter5 = config?.parameter5 ?? ""
        parameter6 = config?.parameter6 ?? ""
        offsiteServer = config?.offsiteServer ?? ""
        backupID = config?.backupID ?? ""
        dateRun = config?.dateRun
        snapshotnum = config?.snapshotnum
        // parameters choosed by user
        parameter8 = config?.parameter8
        parameter9 = config?.parameter9
        parameter10 = config?.parameter10
        parameter11 = config?.parameter11
        parameter12 = config?.parameter12
        parameter13 = config?.parameter13
        parameter14 = config?.parameter14
        rsyncdaemon = config?.rsyncdaemon
        // SSH parameters
        sshport = config?.sshport
        sshkeypathandidentityfile = config?.sshkeypathandidentityfile
        profile = config?.profile
        // Snapshots, day to save and last = 1 or every last=0
        snapdayoffweek = config?.snapdayoffweek
        snaplast = config?.snaplast
        // Pre and post tasks
        executepretask = config?.executepretask
        pretask = config?.pretask
        executeposttask = config?.executeposttask
        posttask = config?.posttask
        haltshelltasksonerror = config?.haltshelltasksonerror
    }
}
