//
//  Logging.swift
//  RsyncSwiftUI
//
//  Created by Thomas Evensen on 23/01/2021.
//

import Foundation
import OSLog

@MainActor
final class Logging {
    var structconfigurations: [SynchronizeConfiguration]?
    var logrecords: [LogRecords]?
    var localeprofile: String?

    var validhiddenIDs: Set<Int> {
        var temp = Set<Int>()
        if let configurations = structconfigurations {
            _ = configurations.map { record in
                temp.insert(record.hiddenID)
            }
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
        newrecord.dateStart = currendate.en_string_from_date()
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

    func setCurrentDateonConfiguration(configrecords: [Typelogdata]) -> [SynchronizeConfiguration] {
        _ = configrecords.map { logdata in
            let hiddenID = logdata.0
            let date = logdata.1
            if let index = structconfigurations?.firstIndex(where: { $0.hiddenID == hiddenID }) {
                // Caution, snapshotnum already increased before logrecord
                if structconfigurations?[index].task == SharedReference.shared.snapshot {
                    increasesnapshotnum(index: index)
                }
                structconfigurations?[index].dateRun = date
            }
        }
        WriteSynchronizeConfigurationJSON(localeprofile, structconfigurations)
        return structconfigurations ?? []
    }

    // Caution, the snapshotnum is alrady increased in
    // setCurrentDateonConfiguration(configrecords: [Typelogdata]).
    // Must set -1 to get correct num in log
    func addlogpermanentstore(schedulerecords: [Typelogdata]) {
        if SharedReference.shared.addsummarylogrecord {
            _ = schedulerecords.map { logdata in
                let hiddenID = logdata.0
                let stats = logdata.1
                let currendate = Date()
                let date = currendate.en_string_from_date()
                if let config = getconfig(hiddenID: hiddenID) {
                    let resultannotaded: String? = if config.task == SharedReference.shared.snapshot {
                        if let snapshotnum = config.snapshotnum {
                            "(" + String(snapshotnum - 1) + ") " + stats
                        } else {
                            "(" + "1" + ") " + stats
                        }
                    } else {
                        stats
                    }
                    var inserted: Bool = addlogexisting(hiddenID: hiddenID,
                                                        result: resultannotaded ?? "",
                                                        date: date)
                    // Record does not exist, create new LogRecord (not inserted)
                    if inserted == false {
                        inserted = addlognew(hiddenID: hiddenID, result: resultannotaded ?? "", date: date)
                    }
                }
            }
            WriteLogRecordsJSON(localeprofile, logrecords)
        }
    }

    init(profile: String?,
         configurations: [SynchronizeConfiguration]?)
    {
        localeprofile = profile
        structconfigurations = configurations
        if localeprofile == SharedConstants().defaultprofile || localeprofile == nil {
            logrecords = ReadLogRecordsJSON().readjsonfilelogrecords(nil, validhiddenIDs)
        } else {
            logrecords = ReadLogRecordsJSON().readjsonfilelogrecords(localeprofile, validhiddenIDs)
        }
        if logrecords == nil {
            logrecords = [LogRecords]()
        }
    }
}
