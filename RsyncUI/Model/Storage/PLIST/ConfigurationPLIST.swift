//
//  ConfigurationPLIST.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 23/05/2021.
//

import Foundation

struct ConfigurationPlist {
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

    // Used when reading PLIST data from store (as part of converting to JSON)
    // And also when creating new records.
    init(_ dictionary: NSDictionary) {
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
}
