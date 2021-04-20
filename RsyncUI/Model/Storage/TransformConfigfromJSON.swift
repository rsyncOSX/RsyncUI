//
//  TransformConfigfromJSON.swift
//  RsyncOSX
//
//  Created by Thomas Evensen on 31/10/2020.
//  Copyright © 2020 Thomas Evensen. All rights reserved.
//
//  swiftlint:disable cyclomatic_complexity function_body_length trailing_comma line_length

import Foundation

struct TransformConfigfromJSON {
    func transform(_ object: EncodeConfiguration) -> Configuration {
        var dayssincelastbackup: String?
        var markdays: Bool = false
        var lastruninseconds: Double? {
            if let date = object.dateRun {
                let lastbackup = date.en_us_date_from_string()
                let seconds: TimeInterval = lastbackup.timeIntervalSinceNow
                return seconds * (-1)
            } else {
                return nil
            }
        }
        // Last run of task
        if object.dateRun != nil {
            if let secondssince = lastruninseconds {
                dayssincelastbackup = String(format: "%.2f", secondssince / (60 * 60 * 24))
                if secondssince / (60 * 60 * 24) > SharedReference.shared.marknumberofdayssince {
                    markdays = true
                }
            }
        }
        let dict: NSMutableDictionary = [
            DictionaryStrings.localCatalog.rawValue: object.localCatalog ?? "",
            DictionaryStrings.offsiteCatalog.rawValue: object.offsiteCatalog ?? "",
            DictionaryStrings.parameter1.rawValue: object.parameter1 ?? "",
            DictionaryStrings.parameter2.rawValue: object.parameter2 ?? "",
            DictionaryStrings.parameter3.rawValue: object.parameter3 ?? "",
            DictionaryStrings.parameter4.rawValue: object.parameter4 ?? "",
            DictionaryStrings.parameter5.rawValue: object.parameter5 ?? "",
            DictionaryStrings.parameter6.rawValue: object.parameter6 ?? "",
            DictionaryStrings.task.rawValue: object.task ?? "",
            DictionaryStrings.hiddenID.rawValue: object.hiddenID ?? 0,
            "lastruninseconds": lastruninseconds ?? 0,
            "dayssincelastbackup": dayssincelastbackup ?? "",
            DictionaryStrings.markdays.rawValue: markdays,
            DictionaryStrings.dateRun.rawValue: object.dateRun ?? "",
        ]
        if object.parameter8?.isEmpty == false {
            dict.setObject(object.parameter8 ?? "", forKey: DictionaryStrings.parameter8.rawValue as NSCopying)
        }
        if object.parameter9?.isEmpty == false {
            dict.setObject(object.parameter9 ?? "", forKey: DictionaryStrings.parameter9.rawValue as NSCopying)
        }
        if object.parameter10?.isEmpty == false {
            dict.setObject(object.parameter10 ?? "", forKey: DictionaryStrings.parameter10.rawValue as NSCopying)
        }
        if object.parameter11?.isEmpty == false {
            dict.setObject(object.parameter11 ?? "", forKey: DictionaryStrings.parameter11.rawValue as NSCopying)
        }
        if object.parameter12?.isEmpty == false {
            dict.setObject(object.parameter12 ?? "", forKey: DictionaryStrings.parameter12.rawValue as NSCopying)
        }
        if object.parameter13?.isEmpty == false {
            dict.setObject(object.parameter13 ?? "", forKey: DictionaryStrings.parameter13.rawValue as NSCopying)
        }
        if object.parameter14?.isEmpty == false {
            dict.setObject(object.parameter14 ?? "", forKey: DictionaryStrings.parameter14.rawValue as NSCopying)
        }
        if object.sshkeypathandidentityfile?.isEmpty == false {
            dict.setObject(object.sshkeypathandidentityfile ?? "", forKey: DictionaryStrings.sshkeypathandidentityfile.rawValue as NSCopying)
        }
        if object.pretask?.isEmpty == false {
            dict.setObject(object.pretask ?? "", forKey: DictionaryStrings.pretask.rawValue as NSCopying)
        }
        if object.posttask?.isEmpty == false {
            dict.setObject(object.posttask ?? "", forKey: DictionaryStrings.posttask.rawValue as NSCopying)
        }
        if object.executepretask != nil {
            dict.setObject(object.executepretask ?? 0, forKey: DictionaryStrings.executepretask.rawValue as NSCopying)
        }
        if object.executeposttask != nil {
            dict.setObject(object.executeposttask ?? 0, forKey: DictionaryStrings.executeposttask.rawValue as NSCopying)
        }
        if object.sshport != nil {
            dict.setObject(object.sshport ?? 22, forKey: DictionaryStrings.sshport.rawValue as NSCopying)
        }
        if object.rsyncdaemon != nil {
            dict.setObject(object.rsyncdaemon ?? 0, forKey: DictionaryStrings.rsyncdaemon.rawValue as NSCopying)
        }
        if object.haltshelltasksonerror != nil {
            dict.setObject(object.haltshelltasksonerror ?? 0, forKey: DictionaryStrings.haltshelltasksonerror.rawValue as NSCopying)
        }
        if object.dateRun?.isEmpty == false {
            dict.setObject(object.dateRun ?? "", forKey: DictionaryStrings.dateRun.rawValue as NSCopying)
        }
        if object.snapdayoffweek?.isEmpty == false {
            dict.setObject(object.snapdayoffweek ?? "", forKey: DictionaryStrings.snapdayoffweek.rawValue as NSCopying)
        }
        if object.snaplast != nil {
            dict.setObject(object.snaplast ?? 0, forKey: DictionaryStrings.snaplast.rawValue as NSCopying)
        }
        if object.snapshotnum != nil {
            dict.setObject(object.snapshotnum ?? 0, forKey: DictionaryStrings.snapshotnum.rawValue as NSCopying)
        }
        if object.backupID?.isEmpty == false {
            dict.setObject(object.backupID ?? "", forKey: DictionaryStrings.backupID.rawValue as NSCopying)
        }
        if object.offsiteServer?.isEmpty == false {
            dict.setObject(object.offsiteServer ?? "", forKey: DictionaryStrings.offsiteServer.rawValue as NSCopying)
        }
        if object.offsiteUsername?.isEmpty == false {
            dict.setObject(object.offsiteUsername ?? "", forKey: DictionaryStrings.offsiteUsername.rawValue as NSCopying)
        }
        return Configuration(dictionary: dict as NSDictionary)
    }
}
