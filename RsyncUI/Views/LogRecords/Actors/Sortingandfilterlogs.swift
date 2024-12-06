//
//  Sortingandfilterlogs.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 06/12/2024.
//

import Foundation
import OSLog

actor Sortingandfilterlogs {
    
    func updatelogsbyfilter(logrecords: [LogRecords]?, filterstring: String, hiddenID: Int) async -> [Log]? {
        Logger.process.info("updatelogsbyfilter(): on main thread: \(Thread.isMain)")
        guard filterstring != "" else { return nil }
        if let logrecords {
            if hiddenID == -1 {
                var merged = [Log]()
                _ = logrecords.map { logrecord in
                    if let logrecords = logrecord.logrecords {
                        merged += [logrecords].flatMap(\.self)
                    }
                }
                let records = merged.sorted(using: [KeyPathComparator(\Log.date, order: .reverse)])
                return records.filter { ($0.dateExecuted?.en_us_date_from_string().long_localized_string_from_date().contains(filterstring)) ?? false || ($0.resultExecuted?.contains(filterstring) ?? false)
                }
            } else {
                if let index = logrecords.firstIndex(where: { $0.hiddenID == hiddenID }),
                   let logrecords = logrecords[index].logrecords
                {
                    let records = logrecords.sorted(using: [KeyPathComparator(\Log.date, order: .reverse)])
                    return records.filter { ($0.dateExecuted?.en_us_date_from_string().long_localized_string_from_date().contains(filterstring)) ?? false || ($0.resultExecuted?.contains(filterstring) ?? false)
                    }
                }
            }
        }
        return nil
    }

    func updatelogsbyhiddenID(logrecords: [LogRecords]?, filterstring: String, hiddenID: Int) async -> [Log]? {
        Logger.process.info("updatelogsbyhiddenID(): on main thread: \(Thread.isMain)")
        if let logrecords {
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
}
