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

actor ActorLogCharts {
    @concurrent
    nonisolated func readjsonfilelogrecords(_ profile: String?,
                                            _ validhiddenIDs: Set<Int>) async -> [LogRecords]?
    {
        let path = await Homepath()
        var filename = ""

        Logger.process.info("ActorLogCharts: readjsonfilelogrecords() MAIN THREAD: \(Thread.isMain) but on \(Thread.current)")

        if let profile, let fullpathmacserial = path.fullpathmacserial {
            filename = fullpathmacserial.appending("/") + profile.appending("/") + SharedConstants().filenamelogrecordsjson
        } else {
            if let fullpathmacserial = path.fullpathmacserial {
                filename = fullpathmacserial.appending("/") + SharedConstants().filenamelogrecordsjson
            }
        }

        Logger.process.info("ActorLogCharts: readjsonfilelogrecords() from \(filename, privacy: .public)")

        let decodeimport = DecodeGeneric()
        do {
            if let data = try
                decodeimport.decodearraydatafileURL(DecodeLogRecords.self, fromwhere: filename)
            {
                Logger.process.info("ActorLogCharts - \(profile ?? "default profile", privacy: .public): DECODE MAIN THREAD: \(Thread.isMain) but on \(Thread.current)")
                return data.compactMap { element in
                    let item = LogRecords(element)
                    return validhiddenIDs.contains(item.hiddenID) ? item : nil
                }
            }

        } catch let e {
            Logger.process.error("ActorLogCharts - \(profile ?? "default profile", privacy: .public): some ERROR reading logrecords from permanent storage")
            let error = e
            await path.propogateerror(error: error)
        }
        return nil
    }

    @concurrent
    nonisolated func updatelogsbyhiddenID(_ logrecords: [LogRecords]?, _ hiddenID: Int) async -> [Log]? {
        Logger.process.info("ActorLogCharts: updatelogsbyhiddenID() MAIN THREAD: \(Thread.isMain) but on \(Thread.current)")
        if let logrecords {
            // hiddenID == -1, merge logrecords for all tasks.
            // if validhiddenID, merge logrecords for a specific task
            if hiddenID == -1 {
                var merged = [Log]()
                _ = logrecords.map { logrecord in
                    if let logrecords = logrecord.logrecords {
                        merged += [logrecords].flatMap(\.self)
                    }
                }
                // return merged.sorted(by: \.date, using: >)
                return merged.sorted(using: [KeyPathComparator(\Log.date, order: .reverse)])
            } else {
                if let index = logrecords.firstIndex(where: { $0.hiddenID == hiddenID }),
                   let logrecords = logrecords[index].logrecords
                {
                    return logrecords.sorted(using: [KeyPathComparator(\Log.date, order: .reverse)])
                }
            }
        }
        return nil
    }

    @concurrent
    nonisolated func parseLogData(from logrecords: [Log]) async -> [LogEntry] {
        // "resultExecuted": "43 files : 0.73 MB in 0.49 seconds"
        logrecords.compactMap { logrecord in
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

            return (files > 10 && size > 5) ? LogEntry(date: logrecord.date,
                                                       files: files,
                                                       transferredMB: size,
                                                       seconds: seconds) : nil
        }
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

/*
 let date: Date
 let numFiles: Int
 let dataTransferredMB: Double
 let seconds: Int

 struct Log: Identifiable, Codable {
     var id = UUID()
     var dateExecuted: String?
     var resultExecuted: String?
     var date: Date {
         dateExecuted?.en_date_from_string() ?? Date()
     }
 }

 "resultExecuted":"43 files : 0.73 MB in 0.49 seconds"

 */
