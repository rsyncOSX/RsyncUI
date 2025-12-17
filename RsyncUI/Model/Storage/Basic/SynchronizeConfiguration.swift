//
//  SynchronizeConfiguration.swift
//  RsyncUI
//

import Foundation

enum NumDayofweek: Int {
    case monday = 2
    case tuesday = 3
    case wednesday = 4
    case thursday = 5
    case friday = 6
    case saturday = 7
    case sunday = 1
}

enum StringDayofweek: String, CaseIterable, Identifiable, CustomStringConvertible {
    case monday
    case tuesday
    case wednesday
    case thursday
    case friday
    case saturday
    case sunday

    var id: String { rawValue }
    var description: String { rawValue.localizedLowercase }
}

enum PlanSnapshots: String, CaseIterable, Identifiable, CustomStringConvertible {
    case every // keepallselcteddayofweek
    case last // islastSelectedDayinMonth

    var id: String { rawValue }
    var description: String { rawValue.localizedLowercase }
}

struct SynchronizeConfiguration: Identifiable, Codable {
    var id = UUID()
    var hiddenID: Int
    var task: String
    var localCatalog: String
    var offsiteCatalog: String
    var offsiteUsername: String
    var parameter4: String?
    var offsiteServer: String
    var backupID: String
    var dateRun: String?
    var snapshotnum: Int?
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
    // Snapshots, day to save and last = 1 or every last=0
    var snapdayoffweek: String?
    var snaplast: Int?
    // task is halted
    var halted: Int

    // Used when reading JSON data from store
    // see in ReadSynchronizeConfigurationJSON
    init(_ data: DecodeSynchronizeConfiguration) {
        backupID = data.backupID ?? ""
        hiddenID = data.hiddenID ?? -1
        localCatalog = data.localCatalog ?? ""
        offsiteCatalog = data.offsiteCatalog ?? ""
        offsiteServer = data.offsiteServer ?? ""
        offsiteUsername = data.offsiteUsername ?? ""
        parameter10 = data.parameter10
        parameter11 = data.parameter11
        parameter12 = data.parameter12
        parameter13 = data.parameter13
        parameter14 = data.parameter14
        parameter4 = data.parameter4
        parameter8 = data.parameter8
        parameter9 = data.parameter9
        rsyncdaemon = data.rsyncdaemon
        sshkeypathandidentityfile = data.sshkeypathandidentityfile
        sshport = data.sshport ?? -1
        task = data.task ?? ""
        // For snapshots
        if let snapshotnum = data.snapshotnum {
            self.snapshotnum = snapshotnum
            snapdayoffweek = data.snapdayoffweek ?? StringDayofweek.sunday.rawValue
            snaplast = data.snaplast ?? 1
        }
        // Last run of task
        dateRun = data.dateRun
        halted = data.halted ?? 0
    }

    // Create an empty record with no values
    init() {
        hiddenID = -1
        task = ""
        localCatalog = ""
        offsiteCatalog = ""
        offsiteUsername = ""
        parameter4 = ""
        offsiteServer = ""
        backupID = ""
        halted = 0
    }
}

extension SynchronizeConfiguration: Hashable, Equatable {
    static func == (lhs: SynchronizeConfiguration, rhs: SynchronizeConfiguration) -> Bool {
        lhs.localCatalog == rhs.localCatalog &&
            lhs.offsiteCatalog == rhs.offsiteCatalog &&
            lhs.offsiteUsername == rhs.offsiteUsername &&
            lhs.offsiteServer == rhs.offsiteServer &&
            lhs.hiddenID == rhs.hiddenID &&
            lhs.task == rhs.task &&
            lhs.parameter4 == rhs.parameter4 &&
            lhs.parameter8 == rhs.parameter8 &&
            lhs.parameter9 == rhs.parameter9 &&
            lhs.parameter10 == rhs.parameter10 &&
            lhs.parameter11 == rhs.parameter11 &&
            lhs.parameter12 == rhs.parameter12 &&
            lhs.parameter13 == rhs.parameter13 &&
            lhs.parameter14 == rhs.parameter14 &&
            lhs.dateRun == rhs.dateRun &&
            lhs.backupID == rhs.backupID &&
            lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(localCatalog)
        hasher.combine(offsiteUsername)
        hasher.combine(offsiteServer)
        hasher.combine(String(hiddenID))
        hasher.combine(task)
        hasher.combine(parameter4)
        hasher.combine(parameter8)
        hasher.combine(parameter9)
        hasher.combine(parameter10)
        hasher.combine(parameter11)
        hasher.combine(parameter12)
        hasher.combine(parameter13)
        hasher.combine(parameter14)
        hasher.combine(dateRun)
        hasher.combine(backupID)
        hasher.combine(id)
    }
}
