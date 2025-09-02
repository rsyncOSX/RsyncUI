//
//  ActorLogChartsData.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 29/08/2025.
//

import DecodeEncodeGeneric
import Foundation
import OSLog

// MARK: - Model for log data

struct LogEntry: Identifiable {
    let id = UUID()
    let date: Date
    let files: Int
    let transferredMB: Double
    let seconds: Double
}

actor ActorLogChartsData {
    // Parse logrecords and extract numbers for synchronize and snapshot tasks
    @concurrent
    nonisolated func parselogrecords(from logrecords: [Log]) async -> [LogEntry] {
        // "resultExecuted": "43 files : 0.73 MB in 0.49 seconds"
        Logger.process.info("ActorLogChartsData: parselogrecords() MAIN THREAD: \(Thread.isMain) but on \(Thread.current)")
        Logger.process.info("ActorLogChartsData: number of records \(logrecords.count, privacy: .public)")
        return logrecords.compactMap { logrecord in
            let numbers = extractNumbersAsDoubles(from: logrecord.resultExecuted ?? "")

            // Snapshot task
            if numbers.count == 4 {
                let files = numbers[1]
                let size = numbers[2]
                let seconds = numbers[3]

                return (seconds > 1 || size > 1 || files > 1) ? LogEntry(date: logrecord.date,
                                                                         files: Int(files),
                                                                         transferredMB: size,
                                                                         seconds: seconds) : nil
                // Synchronize task
            } else {
                let files = numbers[0]
                let size = numbers[1]
                let seconds = numbers[2]

                return (seconds > 1 || size > 1 || files > 1) ? LogEntry(date: logrecord.date,
                                                                         files: Int(files),
                                                                         transferredMB: size,
                                                                         seconds: seconds) : nil
            }
        }
    }

    // Extract numbers as Double values
    private nonisolated func extractNumbersAsDoubles(from string: String) -> [Double] {
        extractNumbers(from: string).compactMap { Double($0) }
    }

    // Extract all numbers as strings
    private nonisolated func extractNumbers(from string: String) -> [String] {
        let pattern = #"\d+(?:\.\d+)?"# // Matches integers and decimals
        let regex = try! NSRegularExpression(pattern: pattern)
        let matches = regex.matches(in: string, range: NSRange(string.startIndex..., in: string))
        return matches.map { match in
            String(string[Range(match.range, in: string)!])
        }
    }

    // By number of files
    // Select the one date with max files transferred, if more records pr date.
    @concurrent
    nonisolated func selectMaxValueFilesDates(from records: [LogEntry]) async -> [LogEntry] {
        Logger.process.info("ActorLogChartsData: selectMaxValueFilesDates() MAIN THREAD: \(Thread.isMain) but on \(Thread.current)")
        Logger.process.info("ActorLogChartsData: number of records IN \(records.count, privacy: .public)")
        let calendar = Calendar.current

        return records.reduce(into: [Date: LogEntry]()) { result, record in
            let dayKey = calendar.startOfDay(for: record.date)

            if let existingRecord = result[dayKey] {
                // Keep the record with higher value
                if record.files > existingRecord.files {
                    result[dayKey] = record
                }
            } else {
                result[dayKey] = record
            }
        }.values.sorted { $0.date > $1.date }
    }

    // By number of files
    // Function to get top N records with highest values by files
    @concurrent
    nonisolated func getTopNRecordsbyfiles(from records: [LogEntry], count: Int) async -> [LogEntry] {
        records
            .sorted { $0.files > $1.files } // Sort by value descending
            .prefix(count) // Take first N items
            .sorted { $0.date > $1.date } // Optional: sort by date for display
    }

    // By number of files
    // Combined approach: get max per day, then top NN overall by files
    @concurrent
    nonisolated func getTopNMaxPerDaybyfiles(from records: [LogEntry], count: Int) async -> [LogEntry] {
        let maxPerDay = await selectMaxValueFilesDates(from: records)
        return await getTopNRecordsbyfiles(from: maxPerDay, count: count)
    }

    // By transferredMB
    // Function to get top N records with highest values by files
    @concurrent
    nonisolated func getTopNRecordsbyMB(from records: [LogEntry], count: Int) async -> [LogEntry] {
        records
            .sorted { $0.transferredMB > $1.transferredMB } // Sort by value descending
            .prefix(count) // Take first N items
            .sorted { $0.date > $1.date } // Optional: sort by date for display
    }

    // By transferredMB
    // Combined approach: get max per day, then top NN overall by files
    @concurrent
    nonisolated func getTopNMaxPerDaybyMB(from records: [LogEntry], count: Int) async -> [LogEntry] {
        let maxPerDay = await selectMaxValueMBDates(from: records)
        return await getTopNRecordsbyMB(from: maxPerDay, count: count)
    }

    // By transferredMB
    // Select the one date with max data transferred, if more records pr date.
    @concurrent
    nonisolated func selectMaxValueMBDates(from records: [LogEntry]) async -> [LogEntry] {
        Logger.process.info("ActorLogChartsData: selectMaxValueMBDates() MAIN THREAD: \(Thread.isMain) but on \(Thread.current)")
        Logger.process.info("ActorLogChartsData: number of records IN \(records.count, privacy: .public)")
        let calendar = Calendar.current

        return records.reduce(into: [Date: LogEntry]()) { result, record in
            let dayKey = calendar.startOfDay(for: record.date)

            if let existingRecord = result[dayKey] {
                // Keep the record with higher value
                if record.transferredMB > existingRecord.transferredMB {
                    result[dayKey] = record
                }
            } else {
                result[dayKey] = record
            }
        }.values.sorted { $0.date > $1.date }
    }
}
