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
    
    @concurrent
    nonisolated func parselogrecords(from logrecords: [Log]) async -> [LogEntry] {
        // "resultExecuted": "43 files : 0.73 MB in 0.49 seconds"
        Logger.process.info("ActorLogChartsData: parselogrecords() MAIN THREAD: \(Thread.isMain) but on \(Thread.current)")
        Logger.process.info("ActorLogChartsData: number of records \(logrecords.count, privacy: .public)")
        return logrecords.compactMap { logrecord in
            
            let numbers = extractNumbersAsDoubles(from: logrecord.resultExecuted ?? "")
            
            // Snapshots
            if numbers.count == 4 {
                let files = numbers[1]
                let size = numbers[2]
                let seconds = numbers[3]

                return (seconds > 1 || size > 1 || files > 1) ? LogEntry(date: logrecord.date,
                                                                         files: Int(files),
                                                                         transferredMB: size,
                                                                         seconds: seconds) : nil
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

    @concurrent
    nonisolated func selectlargestbydate(from records: [LogEntry]) async -> [LogEntry] {
        Logger.process.info("ActorLogChartsData: selectlargestbydate() MAIN THREAD: \(Thread.isMain) but on \(Thread.current)")
        Logger.process.info("ActorLogChartsData: number of records IN \(records.count, privacy: .public)")
        // Group by date
        let grouped = Dictionary(grouping: records, by: { $0.date }).sorted(by: { $0.key > $1.key })
        // For each date, keep only the LogEntry with the greatest files value
        let filtered = grouped.compactMap { _, entries in
            entries.max(by: { $0.files < $1.files })
        }
        return filtered.sorted(using: [KeyPathComparator(\LogEntry.date, order: .forward)])
    }

    // Method 1: Extract all numbers as strings
    private nonisolated func extractNumbers(from string: String) -> [String] {
        let pattern = #"\d+(?:\.\d+)?"# // Matches integers and decimals
        let regex = try! NSRegularExpression(pattern: pattern)
        let matches = regex.matches(in: string, range: NSRange(string.startIndex..., in: string))

        return matches.map { match in
            String(string[Range(match.range, in: string)!])
        }
    }

    // Method 2: Extract numbers as Double values
    private nonisolated func extractNumbersAsDoubles(from string: String) -> [Double] {
        extractNumbers(from: string).compactMap { Double($0) }
    }

    // Method 3: Extract specific numbers with labels
    struct ExecutionResult {
        let fileCount: Int
        let sizeMB: Double
        let timeSeconds: Double
    }

    private nonisolated func parseExecutionResult(from string: String) -> ExecutionResult? {
        let numbers = extractNumbersAsDoubles(from: string)
        guard numbers.count == 3 else { return nil }

        return ExecutionResult(
            fileCount: Int(numbers[0]),
            sizeMB: numbers[1],
            timeSeconds: numbers[2]
        )
    }

    // Main function to select dates with maximum values per day
    nonisolated func selectDatesWithMaxValues(from records: [LogEntry]) async -> [LogEntry] {
        Logger.process.info("ActorLogChartsData: selectDatesWithMaxValues() MAIN THREAD: \(Thread.isMain) but on \(Thread.current)")
        Logger.process.info("ActorLogChartsData: number of records IN \(records.count, privacy: .public)")
        // Group records by day (ignoring time)
        let calendar = Calendar.current
        let groupedByDay = Dictionary(grouping: records) { record in
            calendar.startOfDay(for: record.date)
        }

        // For each day, find the record with the maximum value
        let maxRecords = groupedByDay.compactMap { _, LogEntry -> LogEntry? in
            return LogEntry.max { $0.files < $1.files }
        }
        // Sort by date if needed
        return maxRecords.sorted { $0.date < $1.date }
    }

    // Alternative approach using reduce for more control
    // Select max value by files
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
        }.values.sorted { $0.date < $1.date }
    }
    
    // Alternative approach using reduce for more control
    // Select max value by files
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
        }.values.sorted { $0.date < $1.date }
    }

    // Function to get top N records with highest values
    nonisolated func getTopNRecords(from records: [LogEntry], count: Int) async -> [LogEntry] {
        records
            .sorted { $0.files > $1.files } // Sort by value descending
            .prefix(count) // Take first N items
            .sorted { $0.date < $1.date } // Optional: sort by date for display
    }

    // Combined approach: get max per day, then top 20 overall
    nonisolated func getTopNMaxPerDay(from records: [LogEntry], count: Int) async -> [LogEntry] {
        let maxPerDay = await selectDatesWithMaxValues(from: records)
        return await getTopNRecords(from: maxPerDay, count: count)
    }

    // Get results - top 20 records with highest values
    // let top20Records = getTopNRecords(from: sampleData, count: 20)

    // Or if you want max per day first, then top 20 from those
    // let maxPerDayThenTop20 = getTopNMaxPerDay(from: sampleData, count: 20)
}
