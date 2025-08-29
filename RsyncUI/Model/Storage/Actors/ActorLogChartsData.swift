//
//  ActorLogCharts.swift
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
    let transferredMB: Int
    let seconds: Int
}

actor ActorLogChartsData {

    @concurrent
    nonisolated func parselogrecords(from logrecords: [Log]) async -> [LogEntry] {
        // "resultExecuted": "43 files : 0.73 MB in 0.49 seconds"
        Logger.process.info("ActorLogChartsData: parselogrecords() MAIN THREAD: \(Thread.isMain) but on \(Thread.current)")
        Logger.process.info("ActorLogChartsData: number of records \(logrecords.count, privacy: .public)")
        return logrecords.compactMap { logrecord in
            let intfiles = returnIntNumber(logrecord.resultExecuted ?? "")

            var files = 0
            var size = 0
            var seconds = 0

            if intfiles.count == 5 {
                files = Int(intfiles[0])
                size = intfiles[1]
                if size == 0 {
                    size = 1
                }
                seconds = intfiles[3]
                if seconds == 0 {
                    seconds = 1
                }
            }

            return (seconds > 1  || size > 1 || files > 1) ? LogEntry(date: logrecord.date,
                                                       files: files,
                                                       transferredMB: size,
                                                       seconds: seconds) : nil
            }
        
        }
        
    @concurrent
    nonisolated func selectlargestbydate(from records: [LogEntry]) async -> [LogEntry] {
        Logger.process.info("ActorLogChartsData: selectlargestbydate() MAIN THREAD: \(Thread.isMain) but on \(Thread.current)")
        Logger.process.info("ActorLogChartsData: number of records IN \(records.count, privacy: .public)")
        // Group by date
        let grouped = Dictionary(grouping: records, by: { $0.date }).sorted(by: { $0.key > $1.key })
        // For each date, keep only the LogEntry with the greatest files value
        let filtered = grouped.compactMap { (_, entries) in
            entries.max(by: { $0.files < $1.files })
        }
        Logger.process.info("ActorLogChartsData: number of records OUT \(filtered.count, privacy: .public)")
        return filtered.sorted(using: [KeyPathComparator(\LogEntry.date, order: .forward)])
    }
    

    private nonisolated func returnIntNumber(_ input: String) -> [Int] {
        var numbers: [Int] = []
        let str = input.replacingOccurrences(of: ",", with: "")
        let stringArray = str.components(separatedBy: CharacterSet.decimalDigits.inverted).compactMap { $0.isEmpty == true ? nil : $0 }

        for item in stringArray where item.isEmpty == false {
            if let number = Int(item) {
                numbers.append(number)
            }
        }
        if numbers.count == 0 {
            return [0]
        } else {
            return numbers
        }
    }
}
