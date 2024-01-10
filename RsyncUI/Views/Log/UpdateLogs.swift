//
//  UpdateLogs.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 13/03/2022.
//

import Foundation

final class UpdateLogs {
    private var logrecords: [LogRecords]?
    private var localeprofile: String?

    func deletelogs(uuids: Set<UUID>) {
        if let records = logrecords {
            var indexset = IndexSet()

            for i in 0 ..< records.count {
                for j in 0 ..< uuids.count {
                    if let index = records[i].logrecords?.firstIndex(
                        where: { $0.id == uuids[uuids.index(uuids.startIndex, offsetBy: j)] })
                    {
                        indexset.insert(index)
                    }
                }
                logrecords?[i].logrecords?.remove(atOffsets: indexset)
                indexset.removeAll()
            }
            WriteLogRecordsJSON(localeprofile, logrecords)
        }
    }

    init(profile: String?,
         scheduleConfigurations: [LogRecords]?)
    {
        localeprofile = profile
        logrecords = scheduleConfigurations
    }

    deinit {
        // print("deinit UpdateSchedules")
    }
}
