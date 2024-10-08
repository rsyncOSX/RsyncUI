//
//  SingletaskPrimaryLogging.swift
//  RsyncSwiftUI
//
//  Created by Thomas Evensen on 23/01/2021.
//

import Foundation
import OSLog

@MainActor
class SingletaskPrimaryLogging {
    var structconfigurations: [SynchronizeConfiguration]?
    var logrecords: [LogRecords]?
    var localeprofile: String?

    var validhiddenIDs: Set<Int> {
        var temp = Set<Int>()
        for i in 0 ..< (structconfigurations?.count ?? 0) {
            temp.insert(structconfigurations?[i].hiddenID ?? -1)
        }
        return temp
    }

    func increasesnapshotnum(index: Int) {
        if let num = structconfigurations?[index].snapshotnum {
            structconfigurations?[index].snapshotnum = num + 1
        }
    }

    func addlogexisting(hiddenID: Int, result: String, date: String) -> Bool {
        if let index = logrecords?.firstIndex(where: { $0.hiddenID == hiddenID }) {
            var log = Log()
            log.dateExecuted = date
            log.resultExecuted = result
            if logrecords?[index].logrecords == nil {
                logrecords?[index].logrecords = [Log]()
            }
            logrecords?[index].logrecords?.append(log)
            Logger.process.info("SingletaskPrimaryLogging: added log existing task")
            return true
        } else {
            return false
        }
    }

    func addlognew(hiddenID: Int, result: String, date: String) -> Bool {
        var newrecord = LogRecords()
        newrecord.hiddenID = hiddenID
        let currendate = Date()
        newrecord.dateStart = currendate.en_us_string_from_date()
        var log = Log()
        log.dateExecuted = date
        log.resultExecuted = result
        newrecord.logrecords = [Log]()
        newrecord.logrecords?.append(log)
        logrecords?.append(newrecord)
        Logger.process.info("SingletaskPrimaryLogging: added log new task")
        return true
    }

    func getconfig(hiddenID: Int) -> SynchronizeConfiguration? {
        if let index = structconfigurations?.firstIndex(where: { $0.hiddenID == hiddenID }) {
            return structconfigurations?[index]
        }
        return nil
    }

    init(profile: String?,
         configurations: [SynchronizeConfiguration]?)
    {
        localeprofile = profile
        structconfigurations = configurations
        logrecords = RsyncUIlogrecords(profile, validhiddenIDs).logrecords
        if logrecords == nil {
            logrecords = [LogRecords]()
        }
    }
}
