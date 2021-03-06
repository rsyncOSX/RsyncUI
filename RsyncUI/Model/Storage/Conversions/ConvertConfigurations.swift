//
//  ConvertConfigurations.swift
//  RsyncOSX
//
//  Created by Thomas Evensen on 26/04/2019.
//  Copyright © 2019 Thomas Evensen. All rights reserved.
//
// swiftlint:disable cyclomatic_complexity function_body_length trailing_comma line_length

import Foundation

struct ConvertConfigurations {
    var configurationNSMutableDictionry: NSMutableDictionary?
    var configurations: [Configuration]?

    private func checkparameter(param: String?) -> String? {
        if let parameter = param {
            guard parameter.isEmpty == false else { return nil }
            return parameter
        } else {
            return nil
        }
    }

    init(index: Int, configurations: [Configuration]?) {
        self.configurations = configurations
        if var config = self.configurations?[index] {
            let dict: NSMutableDictionary = [
                DictionaryStrings.task.rawValue: config.task,
                DictionaryStrings.backupID.rawValue: config.backupID,
                DictionaryStrings.localCatalog.rawValue: config.localCatalog,
                DictionaryStrings.offsiteCatalog.rawValue: config.offsiteCatalog,
                DictionaryStrings.offsiteServer.rawValue: config.offsiteServer,
                DictionaryStrings.offsiteUsername.rawValue: config.offsiteUsername,
                DictionaryStrings.parameter1.rawValue: config.parameter1,
                DictionaryStrings.parameter2.rawValue: config.parameter2,
                DictionaryStrings.parameter3.rawValue: config.parameter3,
                DictionaryStrings.parameter4.rawValue: config.parameter4,
                DictionaryStrings.parameter5.rawValue: config.parameter5,
                DictionaryStrings.parameter6.rawValue: config.parameter6,
                DictionaryStrings.dateRun.rawValue: config.dateRun ?? "",
                DictionaryStrings.hiddenID.rawValue: config.hiddenID,
            ]
            if config.profile != nil {
                dict.setObject(config.profile!, forKey: DictionaryStrings.profile.rawValue as NSCopying)
            }
            // All parameters parameter8 - parameter14 are set
            config.parameter8 = checkparameter(param: config.parameter8)
            if config.parameter8 != nil {
                dict.setObject(config.parameter8!, forKey: DictionaryStrings.parameter8.rawValue as NSCopying)
            }
            config.parameter9 = checkparameter(param: config.parameter9)
            if config.parameter9 != nil {
                dict.setObject(config.parameter9!, forKey: DictionaryStrings.parameter9.rawValue as NSCopying)
            }
            config.parameter10 = checkparameter(param: config.parameter10)
            if config.parameter10 != nil {
                dict.setObject(config.parameter10!, forKey: DictionaryStrings.parameter10.rawValue as NSCopying)
            }
            config.parameter11 = checkparameter(param: config.parameter11)
            if config.parameter11 != nil {
                dict.setObject(config.parameter11!, forKey: DictionaryStrings.parameter11.rawValue as NSCopying)
            }
            config.parameter12 = checkparameter(param: config.parameter12)
            if config.parameter12 != nil {
                dict.setObject(config.parameter12!, forKey: DictionaryStrings.parameter12.rawValue as NSCopying)
            }
            config.parameter13 = checkparameter(param: config.parameter13)
            if config.parameter13 != nil {
                dict.setObject(config.parameter13!, forKey: DictionaryStrings.parameter13.rawValue as NSCopying)
            }
            config.parameter14 = checkparameter(param: config.parameter14)
            if config.parameter14 != nil {
                dict.setObject(config.parameter14!, forKey: DictionaryStrings.parameter14.rawValue as NSCopying)
            }
            if config.rsyncdaemon != nil {
                dict.setObject(config.rsyncdaemon!, forKey: DictionaryStrings.rsyncdaemon.rawValue as NSCopying)
            }
            if config.sshport != nil {
                dict.setObject(config.sshport!, forKey: DictionaryStrings.sshport.rawValue as NSCopying)
            }
            if config.snapshotnum != nil {
                dict.setObject(config.snapshotnum!, forKey: DictionaryStrings.snapshotnum.rawValue as NSCopying)
                if config.snaplast != nil {
                    dict.setObject(config.snaplast!, forKey: DictionaryStrings.snaplast.rawValue as NSCopying)
                }
                if config.snapdayoffweek != nil {
                    dict.setObject(config.snapdayoffweek!, forKey: DictionaryStrings.snapdayoffweek.rawValue as NSCopying)
                }
            }
            if config.sshkeypathandidentityfile != nil {
                dict.setObject(config.sshkeypathandidentityfile!, forKey: DictionaryStrings.sshkeypathandidentityfile.rawValue as NSCopying)
            }
            // Pre and post tasks
            if config.pretask != nil {
                dict.setObject(config.pretask!, forKey: DictionaryStrings.pretask.rawValue as NSCopying)
            }
            if config.executepretask != nil {
                dict.setObject(config.executepretask!, forKey: DictionaryStrings.executepretask.rawValue as NSCopying)
            }
            if config.posttask != nil {
                dict.setObject(config.posttask!, forKey: DictionaryStrings.posttask.rawValue as NSCopying)
            }
            if config.executeposttask != nil {
                dict.setObject(config.executeposttask!, forKey: DictionaryStrings.executeposttask.rawValue as NSCopying)
            }
            if config.haltshelltasksonerror != nil {
                dict.setObject(config.haltshelltasksonerror!, forKey: DictionaryStrings.haltshelltasksonerror.rawValue as NSCopying)
            }
            configurationNSMutableDictionry = dict
        }
    }
}
