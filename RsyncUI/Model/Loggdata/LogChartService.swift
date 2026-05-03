//
//  LogChartService.swift
//  RsyncUI
//

import Foundation

struct LogEntry: Identifiable, Equatable {
    let id: String
    let date: Date
    let files: Int
    let transferredMB: Double
    let seconds: Double

    init(date: Date, files: Int, transferredMB: Double, seconds: Double) {
        self.date = date
        self.files = files
        self.transferredMB = transferredMB
        self.seconds = seconds
        id = "\(date.timeIntervalSinceReferenceDate)-\(files)-\(transferredMB)-\(seconds)"
    }
}

enum LogChartMetric: String, Equatable {
    case files
    case transferredMB
}

enum LogChartLimit: Equatable {
    case maxPerDay
    case topNPerDay(Int)
}

enum LogChartReducer {
    static func chartEntries(
        from store: LogStore,
        hiddenID: Int,
        metric: LogChartMetric,
        limit: LogChartLimit
    ) -> [LogEntry] {
        let selectedLogs = logs(from: store, hiddenID: hiddenID)
        let parsedLogs = parsedEntries(from: selectedLogs)
        let maxPerDay = maxEntriesPerDay(from: parsedLogs, metric: metric)

        switch limit {
        case .maxPerDay:
            return maxPerDay
        case let .topNPerDay(count):
            return topEntries(from: maxPerDay, count: count, metric: metric)
        }
    }

    private static func logs(from store: LogStore, hiddenID: Int) -> [Log] {
        if hiddenID == -1 {
            return store
                .compactMap(\.logrecords)
                .flatMap(\.self)
                .sorted(using: [KeyPathComparator(\Log.date, order: .reverse)])
        }

        return store
            .first(where: { $0.hiddenID == hiddenID })?
            .logrecords?
            .sorted(using: [KeyPathComparator(\Log.date, order: .reverse)]) ?? []
    }

    private static func parsedEntries(from logs: [Log]) -> [LogEntry] {
        logs.compactMap { log in
            let numbers = extractNumbersAsDoubles(from: log.resultExecuted ?? "")

            if numbers.count == 4 {
                return LogEntry(
                    date: log.date,
                    files: Int(numbers[1]),
                    transferredMB: numbers[2],
                    seconds: numbers[3]
                )
            }

            if numbers.count == 3 {
                return LogEntry(
                    date: log.date,
                    files: Int(numbers[0]),
                    transferredMB: numbers[1],
                    seconds: numbers[2]
                )
            }

            return nil
        }
    }

    private static func maxEntriesPerDay(from entries: [LogEntry], metric: LogChartMetric) -> [LogEntry] {
        let calendar = Calendar.current

        return entries
            .reduce(into: [Date: LogEntry]()) { result, entry in
                let dayKey = calendar.startOfDay(for: entry.date)

                if let existingEntry = result[dayKey] {
                    if metricValue(for: entry, metric: metric) > metricValue(for: existingEntry, metric: metric) {
                        result[dayKey] = entry
                    }
                } else {
                    result[dayKey] = entry
                }
            }
            .values
            .sorted { $0.date > $1.date }
    }

    private static func topEntries(from entries: [LogEntry], count: Int, metric: LogChartMetric) -> [LogEntry] {
        entries
            .sorted { metricValue(for: $0, metric: metric) > metricValue(for: $1, metric: metric) }
            .prefix(count)
            .sorted { $0.date > $1.date }
    }

    private static func metricValue(for entry: LogEntry, metric: LogChartMetric) -> Double {
        switch metric {
        case .files:
            Double(entry.files)
        case .transferredMB:
            entry.transferredMB
        }
    }

    private static func extractNumbersAsDoubles(from string: String) -> [Double] {
        extractNumbersAsStrings(from: string).compactMap(Double.init)
    }

    private static let numberRegex = try? NSRegularExpression(pattern: #"\d+(?:\.\d+)?"#)

    private static func extractNumbersAsStrings(from string: String) -> [String] {
        guard let numberRegex else { return [] }

        let matches = numberRegex.matches(in: string, range: NSRange(string.startIndex..., in: string))
        return matches.compactMap { match in
            Range(match.range, in: string).map { String(string[$0]) }
        }
    }
}

extension LogStoreService {
    static func chartEntries(
        profile: String?,
        configurations: [SynchronizeConfiguration]?,
        configurationID: SynchronizeConfiguration.ID?,
        metric: LogChartMetric,
        limit: LogChartLimit
    ) async -> [LogEntry] {
        let store = await loadStore(profile: profile, configurations: configurations)
        let hiddenID = configurations?.hiddenID(for: configurationID) ?? -1

        return LogChartReducer.chartEntries(
            from: store,
            hiddenID: hiddenID,
            metric: metric,
            limit: limit
        )
    }
}
