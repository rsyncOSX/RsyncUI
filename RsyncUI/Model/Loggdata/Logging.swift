//
//  Logging.swift
//  RsyncSwiftUI
//
//  Created by Thomas Evensen on 23/01/2021.
//

import Foundation
import OSLog

struct ScheduleLogData {
    let hiddenID: Int
    let stats: String
}

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

    func updateExistingLog(hiddenID: Int, result: String, date: String) -> Bool {
        if let index = logrecords?.firstIndex(where: { $0.hiddenID == hiddenID }) {
            // Extra check that log results contains numbers
            guard extractnumbersasdoubles(from: result).count == 3 ||
                extractnumbersasdoubles(from: result).count == 4 else { return false }

            var log = Log()
            log.dateExecuted = date
            log.resultExecuted = result

            if logrecords?[index].logrecords == nil {
                logrecords?[index].logrecords = [Log]()
            }
            logrecords?[index].logrecords?.append(log)
            return true
        } else {
            return false
        }
    }

    func createNewLog(hiddenID: Int, result: String, date: String) -> Bool {
        // Extra check that log results contains numbers
        guard extractnumbersasdoubles(from: result).count == 3 ||
            extractnumbersasdoubles(from: result).count == 4 else { return false }

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
        return true
    }

    private func getConfig(hiddenID: Int) -> SynchronizeConfiguration? {
        if let index = structconfigurations?.firstIndex(where: { $0.hiddenID == hiddenID }) {
            return structconfigurations?[index]
        }
        return nil
    }

    func setCurrentDateonConfiguration(configrecords: [ScheduleLogData]) -> [SynchronizeConfiguration] {
        _ = configrecords.map { logdata in
            let hiddenID = logdata.hiddenID
            // stats is set to date
            let date = logdata.stats
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

    // Extract numbers as Double values
    private func extractnumbersasdoubles(from string: String) -> [Double] {
        extractnumbersasstrings(from: string).compactMap { Double($0) }
    }

    // Extract all numbers as strings
    private func extractnumbersasstrings(from string: String) -> [String] {
        let pattern = #"\d+(?:\.\d+)?"# // Matches integers and decimals
        let regex = try! NSRegularExpression(pattern: pattern)
        let matches = regex.matches(in: string, range: NSRange(string.startIndex..., in: string))
        return matches.map { match in
            String(string[Range(match.range, in: string)!])
        }
    }

    enum LogError: Error {
        case insertionFailed(ids: [Int])
    }

    func addLogToPermanentStore(scheduleRecords: [ScheduleLogData]) throws {
        let dateString = Date().en_string_from_date()
        var failedInserts: [Int] = []

        for record in scheduleRecords {
            guard let config = getConfig(hiddenID: record.hiddenID) else {
                failedInserts.append(record.hiddenID)
                continue
            }

            let result = formatLogResult(stats: record.stats, config: config)

            let success = updateExistingLog(hiddenID: record.hiddenID, result: result, date: dateString)
                || createNewLog(hiddenID: record.hiddenID, result: result, date: dateString)

            if !success {
                failedInserts.append(record.hiddenID)
            }
        }

        try persistLogs()

        if !failedInserts.isEmpty {
            throw LogError.insertionFailed(ids: failedInserts)
        }
    }

    // Caution, the snapshotnum is alrady increased in
    // setCurrentDateonConfiguration(configrecords: [Typelogdata]).
    // Must set -1 to get correct num in log
    private func formatLogResult(stats: String, config: SynchronizeConfiguration) -> String {
        guard config.task == SharedReference.shared.snapshot else {
            return stats
        }

        let snapshotNumber = max((config.snapshotnum ?? 1) - 1, 1)
        return "(\(snapshotNumber)) \(stats)"
    }

    private func persistLogs() throws {
        // Renamed and potentially throwing version
        WriteLogRecordsJSON(localeprofile, logrecords)
    }

    init(profile: String?,
         configurations: [SynchronizeConfiguration]?)
    {
        localeprofile = profile
        structconfigurations = configurations
        if localeprofile == nil {
            logrecords = ReadLogRecordsJSON().readjsonfilelogrecords(nil, validhiddenIDs)
        } else {
            logrecords = ReadLogRecordsJSON().readjsonfilelogrecords(localeprofile, validhiddenIDs)
        }
        if logrecords == nil {
            logrecords = [LogRecords]()
        }
    }
}
