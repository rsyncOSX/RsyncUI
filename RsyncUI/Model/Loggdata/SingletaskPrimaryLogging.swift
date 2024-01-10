//
//  SingletaskPrimaryLogging.swift
//  RsyncSwiftUI
//
//  Created by Thomas Evensen on 23/01/2021.
//

import Foundation
import OSLog

class SingletaskPrimaryLogging {
    var structconfigurations: [Configuration]?
    var logrecords: [LogRecords]?
    var localeprofile: String?
    var localehiddenID: Int?

    func setCurrentDateonConfiguration() {
        if let hiddenID = localehiddenID,
           let index = structconfigurations?.firstIndex(where: { $0.hiddenID == hiddenID })
        {
            // Caution, snapshotnum already increased before logrecord
            if structconfigurations?[index].task == SharedReference.shared.snapshot {
                increasesnapshotnum(index: index)
            }
            let currendate = Date()
            structconfigurations?[index].dateRun = currendate.en_us_string_from_date()
            WriteConfigurationJSON(localeprofile, structconfigurations)
        }
    }

    func increasesnapshotnum(index: Int) {
        if let num = structconfigurations?[index].snapshotnum {
            structconfigurations?[index].snapshotnum = num + 1
        }
    }

    // Caution, the snapshotnum is alrady increased in setCurrentDateonConfiguration().
    // Must set -1 to get correct num in log
    func addlogpermanentstore(outputrsync: [String]?) {
        if let hiddenID = localehiddenID {
            if SharedReference.shared.detailedlogging {
                let stats = Numbers(outputrsync ?? []).stats()
                // Set the current date
                let currendate = Date()
                let date = currendate.en_us_string_from_date()
                if let config = getconfig(hiddenID: hiddenID) {
                    var resultannotaded: String?
                    if config.task == SharedReference.shared.snapshot {
                        if let snapshotnum = config.snapshotnum {
                            resultannotaded = "(" + String(snapshotnum - 1) + ") " + stats
                        } else {
                            resultannotaded = "(" + "1" + ") " + stats
                        }
                    } else {
                        resultannotaded = stats
                    }
                    var inserted: Bool = addlogexisting(hiddenID: hiddenID, result: resultannotaded ?? "", date: date)
                    // Record does not exist, create new Schedule (not inserted)
                    if inserted == false {
                        inserted = addlognew(hiddenID: hiddenID, result: resultannotaded ?? "", date: date)
                    }
                    if inserted {
                        WriteLogRecordsJSON(localeprofile, logrecords)
                    }
                    _ = Logfile(TrimTwo(outputrsync ?? []).trimmeddata, error: false)
                }
            }
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
            // newrecord.schedule = Scheduletype.manuel.rawValue
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

    func getconfig(hiddenID: Int) -> Configuration? {
        if let index = structconfigurations?.firstIndex(where: { $0.hiddenID == hiddenID }) {
            return structconfigurations?[index]
        }
        return nil
    }

    init(profile: String?,
         hiddenID: Int?,
         configurations: [Configuration]?,
         validhiddenIDs: Set<Int>)
    {
        localeprofile = profile
        localehiddenID = hiddenID
        structconfigurations = configurations
        logrecords = AllLogs(profile: profile, validhiddenIDs: validhiddenIDs).logrecords
        if logrecords == nil {
            logrecords = [LogRecords]()
        }
    }

    deinit {
        // print("deinit SingletaskPrimaryLogging")
    }
}
