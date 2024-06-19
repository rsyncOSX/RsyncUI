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
    var localehiddenID: Int?

    func increasesnapshotnum(index: Int) {
        if let num = structconfigurations?[index].snapshotnum {
            structconfigurations?[index].snapshotnum = num + 1
        }
    }

    func addlogexisting(hiddenID: Int, result: String, date: String) -> Bool {
        let configdata = GetConfigurationData(configurations: structconfigurations)
        if SharedReference.shared.synctasks.contains(configdata.getconfigurationdata(hiddenID, resource: .task) ?? "") {
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
            }
        }
        return false
    }

    func addlognew(hiddenID: Int, result: String, date: String) -> Bool {
        let configdata = GetConfigurationData(configurations: structconfigurations)
        if SharedReference.shared.synctasks.contains(configdata.getconfigurationdata(hiddenID, resource: .task) ?? "") {
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
        return false
    }

    func getconfig(hiddenID: Int) -> SynchronizeConfiguration? {
        if let index = structconfigurations?.firstIndex(where: { $0.hiddenID == hiddenID }) {
            return structconfigurations?[index]
        }
        return nil
    }

    init(profile: String?,
         hiddenID: Int?,
         configurations: [SynchronizeConfiguration]?)
    {
        localeprofile = profile
        localehiddenID = hiddenID
        structconfigurations = configurations
        var validhiddenIDs = Set<Int>()
        if let configurations = configurations {
            for i in 0 ..< configurations.count {
                validhiddenIDs.insert(configurations[i].hiddenID)
            }
        }
        logrecords = RsyncUIlogrecords(profile, validhiddenIDs).logrecords
        if logrecords == nil {
            logrecords = [LogRecords]()
        }
    }
}
