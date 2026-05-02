//
//  ActorReadLogRecords.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 04/12/2024.
//

import DecodeEncodeGeneric
import Foundation
import OSLog

struct LogEntry: Identifiable {
    let id = UUID()
    let date: Date
    let files: Int
    let transferredMB: Double
    let seconds: Double
}

actor ActorReadLogRecords {
    func readjsonfilelogrecords(_ profile: String?,
                                _ validhiddenIDs: Set<Int>) async -> [LogRecords]? {
        let path = await Homepath()
        var filename = ""
        Logger.process.debugThreadOnly("ActorReadLogRecordsJSON: readjsonfilelogrecords()")
        if let profile, let fullpathmacserial = path.fullpathmacserial {
            filename = fullpathmacserial.appending("/") + profile.appending("/") + SharedConstants().filenamelogrecordsjson
        } else {
            if let fullpathmacserial = path.fullpathmacserial {
                filename = fullpathmacserial.appending("/") + SharedConstants().filenamelogrecordsjson
            }
        }

        Logger.process.debugMessageOnly("ActorReadLogRecordsJSON: readjsonfilelogrecords() from \(filename)")

        let decodeimport = DecodeGeneric()
        do {
            let data = try
                decodeimport.decodeArray(DecodeLogRecords.self, fromFile: filename)

            Logger.process.debugThreadOnly("ActorReadLogRecordsJSON - \(profile ?? "default")")
            return data.compactMap { element in
                let item = LogRecords(element)
                return validhiddenIDs.contains(item.hiddenID) ? item : nil
            }
        } catch {
            let profileName = profile ?? "default profile"
            Logger.process.errorMessageOnly(
                "ActorReadLogRecordsJSON - \(profileName): some ERROR reading logrecords from permanent storage"
            )
        }
        return nil
    }

    func updatelogsbyhiddenID(_ logrecords: [LogRecords]?, _ hiddenID: Int) async -> [Log]? {
        Logger.process.debugThreadOnly("ActorReadLogRecordsJSON: updatelogsbyhiddenID()")
        if let logrecords {
            // hiddenID == -1, merge logrecords for all tasks.
            // if validhiddenID, merge logrecords for a specific task
            if hiddenID == -1 {
                var merged = [Log]()
                for logrecord in logrecords {
                    if let logrecords = logrecord.logrecords {
                        merged += [logrecords].flatMap(\.self)
                    }
                }
                // return merged.sorted(by: \.date, using: >)
                return merged.sorted(using: [KeyPathComparator(\Log.date, order: .reverse)])
            } else {
                if let index = logrecords.firstIndex(where: { $0.hiddenID == hiddenID }),
                   let logrecords = logrecords[index].logrecords {
                    return logrecords.sorted(using: [KeyPathComparator(\Log.date, order: .reverse)])
                }
            }
        }
        return nil
    }

    func updatelogsbyfilter(_ logrecords: [LogRecords]?, _ filterstring: String, _ hiddenID: Int) async -> [Log]? {
        Logger.process.debugThreadOnly("ActorReadLogRecords: updatelogsbyfilter()")
        guard filterstring != "" else { return nil }
        if let logrecords {
            if hiddenID == -1 {
                var merged = [Log]()
                for logrecord in logrecords {
                    if let logrecords = logrecord.logrecords {
                        merged += [logrecords].flatMap(\.self)
                    }
                }
                let records = merged.sorted(using: [KeyPathComparator(\Log.date, order: .reverse)])
                return records.filter { record in
                    let dateString = record.dateExecuted?.en_date_from_string().long_localized_string_from_date() ?? ""
                    let dateMatch = dateString.contains(filterstring)
                    let resultMatch = (record.resultExecuted?.contains(filterstring)) ?? false
                    return dateMatch || resultMatch
                }
            } else {
                if let index = logrecords.firstIndex(where: { $0.hiddenID == hiddenID }),
                   let logrecords = logrecords[index].logrecords {
                    let records = logrecords.sorted(using: [KeyPathComparator(\Log.date, order: .reverse)])
                    return records.filter { record in
                        let dateString = record.dateExecuted?.en_date_from_string().long_localized_string_from_date() ?? ""
                        let dateMatch = dateString.contains(filterstring)
                        let resultMatch = (record.resultExecuted?.contains(filterstring)) ?? false
                        return dateMatch || resultMatch
                    }
                }
            }
        }
        return nil
    }

    func deleteLogs(_ uuids: Set<UUID>,
                    logrecords: [LogRecords]?) async -> [LogRecords]? {
        var records = logrecords

        Logger.process.debugThreadOnly("ActorReadLogRecords: deletelogs()")

        // Convert to Set for O(1) lookup instead of O(n)
        let uuidsToDelete = uuids

        for index in 0 ..< (records?.count ?? 0) {
            // Remove in one pass instead of building IndexSet
            records?[index].logrecords?.removeAll { record in
                uuidsToDelete.contains(record.id)
            }
        }

        return records
    }

    /// Parse logrecords and extract numbers for synchronize and snapshot tasks
    /// Extract all logrecords, sorting by number of files or transferred size in MB later
    func parselogrecords(from logrecords: [Log]) async -> [LogEntry] {
        // "resultExecuted": "43 files : 0.73 MB in 0.49 seconds"
        Logger.process.debugThreadOnly("ActorReadLogRecords: parselogrecords()")
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

    /// Extract numbers as Double values
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

    /// By number of files
    /// Select the one date with max files transferred, if more records pr date.
    func parsemaxfilesbydate(from records: [LogEntry]) async -> [LogEntry] {
        Logger.process.debugThreadOnly("ActorReadLogRecords: parsemaxfilesbydate()")
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

    /// By number of files, get max per day, then top NN overall by files
    func parsemaxNNfilesbydate(from records: [LogEntry], count: Int) async -> [LogEntry] {
        let maxPerDay = await parsemaxfilesbydate(from: records)
        return await getTopNRecordsbyfiles(from: maxPerDay, count: count)
    }

    private nonisolated func getTopNRecordsbyfiles(from records: [LogEntry], count: Int) async -> [LogEntry] {
        records
            .sorted { $0.files > $1.files } // Sort by value descending
            .prefix(count) // Take first N items
            .sorted { $0.date > $1.date } // Optional: sort by date for display
    }

    /// By transferred size (in MB), get max per day, then top NN overall by files
    func parsemaxNNfilesbytransferredsize(from records: [LogEntry], count: Int) async -> [LogEntry] {
        let maxPerDay = await parsemaxfilesbytransferredsize(from: records)
        return await getTopNRecordsbyMB(from: maxPerDay, count: count)
    }

    private nonisolated func getTopNRecordsbyMB(from records: [LogEntry], count: Int) async -> [LogEntry] {
        records
            .sorted { $0.transferredMB > $1.transferredMB } // Sort by value descending
            .prefix(count) // Take first N items
            .sorted { $0.date > $1.date } // Optional: sort by date for display
    }

    /// By transferred size (in MB)
    /// Select the one date with max data transferred, if more records pr date.
    func parsemaxfilesbytransferredsize(from records: [LogEntry]) async -> [LogEntry] {
        Logger.process.debugThreadOnly("ActorReadLogRecords: parsemaxfilesbytransferredsize()")
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

    deinit {
        Logger.process.debugMessageOnly("ActorReadLogRecords: DEINIT")
    }
}
