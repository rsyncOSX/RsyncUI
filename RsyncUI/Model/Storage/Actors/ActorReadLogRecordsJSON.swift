//
//  ActorReadLogRecordsJSON.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 04/12/2024.
//

import DecodeEncodeGeneric
import Foundation
import OSLog

actor ActorReadLogRecordsJSON {
    @concurrent
    nonisolated func readjsonfilelogrecords(_ profile: String?,
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

    @concurrent
    nonisolated func updatelogsbyhiddenID(_ logrecords: [LogRecords]?, _ hiddenID: Int) async -> [Log]? {
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

    @concurrent
    nonisolated func updatelogsbyfilter(_ logrecords: [LogRecords]?, _ filterstring: String, _ hiddenID: Int) async -> [Log]? {
        Logger.process.debugThreadOnly("ActorReadLogRecordsJSON: updatelogsbyfilter()")
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

    @concurrent
    func deleteLogs(_ uuids: Set<UUID>,
                    logrecords: [LogRecords]?) async -> [LogRecords]? {
        var records = logrecords

        Logger.process.debugThreadOnly("ActorReadLogRecordsJSON: deletelogs()")

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

    deinit {
        Logger.process.debugMessageOnly("ActorReadLogRecordsJSON: DEINIT")
    }
}
