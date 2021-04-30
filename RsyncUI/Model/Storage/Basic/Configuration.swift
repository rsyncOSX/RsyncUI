//
//  Created by Thomas Evensen on 08/02/16.
//  Copyright © 2016 Thomas Evensen. All rights reserved.
//
// swiftlint:disable cyclomatic_complexity function_body_length line_length

import Foundation

enum NumDayofweek: Int {
    case Monday = 2
    case Tuesday = 3
    case Wednesday = 4
    case Thursday = 5
    case Friday = 6
    case Saturday = 7
    case Sunday = 1
}

enum StringDayofweek: String, CaseIterable, Identifiable, CustomStringConvertible {
    case Monday
    case Tuesday
    case Wednesday
    case Thursday
    case Friday
    case Saturday
    case Sunday

    var id: String { rawValue }
    var description: String { rawValue.localizedLowercase }
}

enum PlanSnapshots: String, CaseIterable, Identifiable, CustomStringConvertible {
    case Every // keepallselcteddayofweek
    case Last // islastSelectedDayinMonth

    var id: String { rawValue }
    var description: String { rawValue.localizedLowercase }
}

struct Configuration: Identifiable, Codable {
    var id = UUID()
    var hiddenID: Int
    var task: String
    var localCatalog: String
    var offsiteCatalog: String
    var offsiteUsername: String
    var parameter1: String
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
    // Calculated days since last backup
    var dayssincelastbackup: String?
    var markdays: Bool = false
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

    var lastruninseconds: Double? {
        if let date = dateRun {
            let lastbackup = date.en_us_date_from_string()
            let seconds: TimeInterval = lastbackup.timeIntervalSinceNow
            return seconds * (-1)
        } else {
            return nil
        }
    }

    init(dictionary: NSDictionary) {
        // Parameters 1 - 6 is mandatory, set by RsyncOSX.
        hiddenID = (dictionary.object(forKey: DictionaryStrings.hiddenID.rawValue) as? Int) ?? 0
        task = dictionary.object(forKey: DictionaryStrings.task.rawValue) as? String ?? ""
        localCatalog = dictionary.object(forKey: DictionaryStrings.localCatalog.rawValue) as? String ?? ""
        offsiteCatalog = dictionary.object(forKey: DictionaryStrings.offsiteCatalog.rawValue) as? String ?? ""
        offsiteUsername = dictionary.object(forKey: DictionaryStrings.offsiteUsername.rawValue) as? String ?? ""
        parameter1 = dictionary.object(forKey: DictionaryStrings.parameter1.rawValue) as? String ?? ""
        parameter2 = dictionary.object(forKey: DictionaryStrings.parameter2.rawValue) as? String ?? ""
        parameter3 = dictionary.object(forKey: DictionaryStrings.parameter3.rawValue) as? String ?? ""
        parameter4 = dictionary.object(forKey: DictionaryStrings.parameter4.rawValue) as? String ?? ""
        parameter5 = dictionary.object(forKey: DictionaryStrings.parameter5.rawValue) as? String ?? ""
        parameter6 = dictionary.object(forKey: DictionaryStrings.parameter6.rawValue) as? String ?? ""
        offsiteServer = dictionary.object(forKey: DictionaryStrings.offsiteServer.rawValue) as? String ?? ""
        backupID = dictionary.object(forKey: DictionaryStrings.backupID.rawValue) as? String ?? ""
        if let snapshotnum = dictionary.object(forKey: DictionaryStrings.snapshotnum.rawValue) as? Int {
            self.snapshotnum = snapshotnum
            snapdayoffweek = dictionary.object(forKey: DictionaryStrings.snapdayoffweek.rawValue) as? String ?? StringDayofweek.Sunday.rawValue
            snaplast = dictionary.object(forKey: DictionaryStrings.snaplast.rawValue) as? Int ?? 1
        }
        // Last run of task
        if let dateRun = dictionary.object(forKey: DictionaryStrings.dateRun.rawValue) {
            self.dateRun = dateRun as? String
            if let secondssince = lastruninseconds {
                dayssincelastbackup = String(format: "%.2f", secondssince / (60 * 60 * 24))
                if secondssince / (60 * 60 * 24) > SharedReference.shared.marknumberofdayssince {
                    markdays = true
                }
            }
        }
        // Parameters 8 - 14 is user selected, as well as ssh parameters.
        if let parameter8 = dictionary.object(forKey: DictionaryStrings.parameter8.rawValue) {
            self.parameter8 = parameter8 as? String
        }
        if let parameter9 = dictionary.object(forKey: DictionaryStrings.parameter9.rawValue) {
            self.parameter9 = parameter9 as? String
        }
        if let parameter10 = dictionary.object(forKey: DictionaryStrings.parameter10.rawValue) {
            self.parameter10 = parameter10 as? String
        }
        if let parameter11 = dictionary.object(forKey: DictionaryStrings.parameter11.rawValue) {
            self.parameter11 = parameter11 as? String
        }
        if let parameter12 = dictionary.object(forKey: DictionaryStrings.parameter12.rawValue) {
            self.parameter12 = parameter12 as? String
        }
        if let parameter13 = dictionary.object(forKey: DictionaryStrings.parameter13.rawValue) {
            self.parameter13 = parameter13 as? String
        }
        if let parameter14 = dictionary.object(forKey: DictionaryStrings.parameter14.rawValue) {
            self.parameter14 = parameter14 as? String
        }
        if let rsyncdaemon = dictionary.object(forKey: DictionaryStrings.rsyncdaemon.rawValue) {
            self.rsyncdaemon = rsyncdaemon as? Int
        }
        if let sshport = dictionary.object(forKey: DictionaryStrings.sshport.rawValue) {
            self.sshport = sshport as? Int
        }
        if let sshidentityfile = dictionary.object(forKey: DictionaryStrings.sshkeypathandidentityfile.rawValue) {
            sshkeypathandidentityfile = sshidentityfile as? String
        }
        // Pre and post tasks
        if let pretask = dictionary.object(forKey: DictionaryStrings.pretask.rawValue) {
            self.pretask = pretask as? String
        }
        if let executepretask = dictionary.object(forKey: DictionaryStrings.executepretask.rawValue) {
            self.executepretask = executepretask as? Int
        }
        if let posttask = dictionary.object(forKey: DictionaryStrings.posttask.rawValue) {
            self.posttask = posttask as? String
        }
        if let executeposttask = dictionary.object(forKey: DictionaryStrings.executeposttask.rawValue) {
            self.executeposttask = executeposttask as? Int
        }
        if let haltshelltasksonerror = dictionary.object(forKey: DictionaryStrings.haltshelltasksonerror.rawValue) {
            self.haltshelltasksonerror = haltshelltasksonerror as? Int
        }
    }

    // Codable init
    init(config: Self) {
        hiddenID = config.hiddenID
        task = config.task
        localCatalog = config.localCatalog
        offsiteCatalog = config.offsiteCatalog
        offsiteUsername = config.offsiteUsername
        parameter1 = config.parameter1
        parameter2 = config.parameter2
        parameter3 = config.parameter3
        parameter4 = config.parameter4
        parameter5 = config.parameter5
        parameter6 = config.parameter6
        offsiteServer = config.offsiteServer
        backupID = config.backupID
        dateRun = config.dateRun
        snapshotnum = config.snapshotnum
        // parameters choosed by user
        parameter8 = config.parameter8
        parameter9 = config.parameter9
        parameter10 = config.parameter10
        parameter11 = config.parameter11
        parameter12 = config.parameter12
        parameter13 = config.parameter13
        parameter14 = config.parameter14
        rsyncdaemon = config.rsyncdaemon
        // SSH parameters
        sshport = config.sshport
        sshkeypathandidentityfile = config.sshkeypathandidentityfile
        profile = config.profile
        // Snapshots, day to save and last = 1 or every last=0
        snapdayoffweek = config.snapdayoffweek
        snaplast = config.snaplast
        // Pre and post tasks
        executepretask = config.executepretask
        pretask = config.pretask
        executeposttask = config.executeposttask
        posttask = config.posttask
        haltshelltasksonerror = config.haltshelltasksonerror
    }
}

extension Configuration: Hashable, Equatable {
    static func == (lhs: Configuration, rhs: Configuration) -> Bool {
        return lhs.localCatalog == rhs.localCatalog &&
            lhs.offsiteCatalog == rhs.offsiteCatalog &&
            lhs.offsiteUsername == rhs.offsiteUsername &&
            lhs.offsiteServer == rhs.offsiteServer &&
            lhs.hiddenID == rhs.hiddenID &&
            lhs.task == rhs.task &&
            lhs.parameter1 == rhs.parameter1 &&
            lhs.parameter2 == rhs.parameter2 &&
            lhs.parameter3 == rhs.parameter3 &&
            lhs.parameter4 == rhs.parameter4 &&
            lhs.parameter5 == rhs.parameter5 &&
            lhs.parameter6 == rhs.parameter6 &&
            lhs.parameter8 == rhs.parameter8 &&
            lhs.parameter9 == rhs.parameter9 &&
            lhs.parameter10 == rhs.parameter10 &&
            lhs.parameter11 == rhs.parameter11 &&
            lhs.parameter12 == rhs.parameter12 &&
            lhs.parameter13 == rhs.parameter13 &&
            lhs.parameter14 == rhs.parameter14 &&
            lhs.dateRun == rhs.dateRun
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(localCatalog)
        hasher.combine(offsiteUsername)
        hasher.combine(offsiteServer)
        hasher.combine(String(hiddenID))
        hasher.combine(task)
        hasher.combine(parameter1)
        hasher.combine(parameter2)
        hasher.combine(parameter3)
        hasher.combine(parameter4)
        hasher.combine(parameter5)
        hasher.combine(parameter6)
        hasher.combine(parameter8)
        hasher.combine(parameter9)
        hasher.combine(parameter10)
        hasher.combine(parameter11)
        hasher.combine(parameter12)
        hasher.combine(parameter13)
        hasher.combine(parameter14)
        hasher.combine(dateRun)
    }
}
