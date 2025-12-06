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
    // Extract all logrecords, sorting by number of files or transferred size in MB later
    @concurrent
    nonisolated func parselogrecords(from logrecords: [Log]) async -> [LogEntry] {
        // "resultExecuted": "43 files : 0.73 MB in 0.49 seconds"
        Logger.process.debugThreadOnly("ActorLogChartsData: parselogrecords()")
        Logger.process.debugMessageOnly("ActorLogChartsData: number of records \(logrecords.count)")
        // return logrecords.compactMap { logrecord in
        return logrecords.compactMap { logrecord in
            let numbers = extractnumbersasdoubles(from: logrecord.resultExecuted ?? "")

            // Snapshot task
            if numbers.count == 4 {
                let files = numbers[1]
                let size = numbers[2]
                let seconds = numbers[3]
                return LogEntry(date: logrecord.date,
                                files: Int(files),
                                transferredMB: size,
                                seconds: seconds)
                // Synchronize task
            } else if numbers.count == 3 {
                let files = numbers[0]
                let size = numbers[1]
                let seconds = numbers[2]
                return LogEntry(date: logrecord.date,
                                files: Int(files),
                                transferredMB: size,
                                seconds: seconds)
            } else {
                return nil
            }
        }
    }

    // Extract numbers as Double values
    private nonisolated func extractnumbersasdoubles(from string: String) -> [Double] {
        extractNumbersAsStrings(from: string).compactMap { Double($0) }
    }

    private static let numberRegex: NSRegularExpression? = try? NSRegularExpression(pattern: #"\d+(?:\.\d+)?"#)

    private nonisolated func extractNumbersAsStrings(from string: String) -> [String] {
        guard let regex = Self.numberRegex else { return [] }
        let matches = regex.matches(in: string, range: NSRange(string.startIndex..., in: string))
        return matches.compactMap { match in
            Range(match.range, in: string).map { String(string[$0]) }
        }
    }

    // By number of files
    // Select the one date with max files transferred, if more records pr date.
    @concurrent
    nonisolated func parsemaxfilesbydate(from records: [LogEntry]) async -> [LogEntry] {
        Logger.process.debugThreadOnly("ActorLogChartsData: parsemaxfilesbydate()")
        Logger.process.debugMessageOnly("ActorLogChartsData: number of records IN \(records.count)")

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

    // By number of files, get max per day, then top NN overall by files
    @concurrent
    nonisolated func parsemaxNNfilesbydate(from records: [LogEntry], count: Int) async -> [LogEntry] {
        let maxPerDay = await parsemaxfilesbydate(from: records)
        return await getTopNRecordsbyfiles(from: maxPerDay, count: count)
    }

    private nonisolated func getTopNRecordsbyfiles(from records: [LogEntry], count: Int) async -> [LogEntry] {
        records
            .sorted { $0.files > $1.files } // Sort by value descending
            .prefix(count) // Take first N items
            .sorted { $0.date > $1.date } // Optional: sort by date for display
    }

    // By transferred size (in MB), get max per day, then top NN overall by files
    @concurrent
    nonisolated func parsemaxNNfilesbytransferredsize(from records: [LogEntry], count: Int) async -> [LogEntry] {
        let maxPerDay = await parsemaxfilesbytransferredsize(from: records)
        return await getTopNRecordsbyMB(from: maxPerDay, count: count)
    }

    private nonisolated func getTopNRecordsbyMB(from records: [LogEntry], count: Int) async -> [LogEntry] {
        records
            .sorted { $0.transferredMB > $1.transferredMB } // Sort by value descending
            .prefix(count) // Take first N items
            .sorted { $0.date > $1.date } // Optional: sort by date for display
    }

    // By transferred size (in MB)
    // Select the one date with max data transferred, if more records pr date.
    @concurrent
    nonisolated func parsemaxfilesbytransferredsize(from records: [LogEntry]) async -> [LogEntry] {
        Logger.process.debugThreadOnly("ActorLogChartsData: parsemaxfilesbytransferredsize()")
        Logger.process.debugMessageOnly("ActorLogChartsData: number of records IN \(records.count)")
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
