//
//  Snapshotlogsandcatalogs.swift
//  RsyncOSX
//
//  Created by Thomas Evensen on 22.01.2018.
//  Copyright © 2018 Thomas Evensen. All rights reserved.
//

import Foundation

final class Snapshotlogsandcatalogs: Snapshotcatalogs {
    // Number of local logrecords
    var logrecordssnapshot: [LogrecordSnapshot]?
    var firstsnapshotctalogNOdelete: String?
    var lastsnapshotctalogNOdelete: String?

    // Calculating days since snaphot was executed
    private func calculateddayssincesynchronize() {
        for i in 0 ..< (logrecordssnapshot?.count ?? 0) {
            if let dateRun = logrecordssnapshot?[i].dateExecuted {
                if let secondssince = calculatedays(datestringlocalized: dateRun) {
                    logrecordssnapshot?[i].days = String(format: "%.2f", secondssince / (60 * 60 * 24))
                    logrecordssnapshot?[i].seconds = Int(secondssince)
                }
            }
        }
    }

    // Merging remote snaphotcatalogs and existing logs
    private func mergeremotecatalogsandlogs() {
        var adjustedlogrecords = [LogrecordSnapshot]()
        let mycatalogs = catalogsanddates
        var mylogrecords = logrecordssnapshot
        // Loop through all real catalogs, find the corresponding logrecord if any
        // and add the adjusted record
        for i in 0 ..< (mycatalogs?.count ?? 0) {
            // Real snapshotcatalog collected from remote and
            // drop the "./" and add "(" and ")" before filter
            let realsnapshotcatalog = "(" + (mycatalogs?[i].catalog ?? "").dropFirst(2) + ")"
            let record = mylogrecords?.filter { $0.resultExecuted.contains(realsnapshotcatalog) }
            // Found one record
            if record?.count ?? 0 > 0 {
                if var record = record?[0] {
                    let catalogelementlog = record.resultExecuted.split(separator: " ")[0]
                    let snapshotcatalogfromschedulelog = "./" + catalogelementlog.dropFirst().dropLast()
                    let uuid = record.id
                    record.period = "... no tag ..."
                    record.snapshotCatalog = snapshotcatalogfromschedulelog
                    adjustedlogrecords.append(record)
                    // Remove that record
                    if let index = mylogrecords?.firstIndex(where: { $0.id == uuid }) {
                        mylogrecords?.remove(at: index)
                    }
                }
            }
        }
        logrecordssnapshot = adjustedlogrecords.sorted { cat1, cat2 -> Bool in
            if let cat1 = cat1.snapshotCatalog,
               let cat2 = cat2.snapshotCatalog
            {
                return (Int(cat1.dropFirst(2)) ?? 0) > (Int(cat2.dropFirst(2)) ?? 0)
            }
            return false
        }
        // Add records to the StateObject for use in View
        mysnapshotdata?.setsnapshotdata(logrecordssnapshot)
        guard logrecordssnapshot?.count ?? 0 > 0 else { return }
        firstsnapshotctalogNOdelete = logrecordssnapshot?[(logrecordssnapshot?.count ?? 0) - 1].snapshotCatalog
        lastsnapshotctalogNOdelete = logrecordssnapshot?[0].snapshotCatalog
    }

    func calculatedays(datestringlocalized: String) -> Double? {
        guard datestringlocalized != "" else { return nil }
        let lastbackup = datestringlocalized.localized_date_from_string()
        let seconds: TimeInterval = lastbackup.timeIntervalSinceNow
        return seconds * -1
    }

    func countbydays(num: Double) -> Int {
        guard logrecordssnapshot?.count ?? 0 > 0 else { return 0 }
        var j = 0
        for i in 0 ..< (logrecordssnapshot?.count ?? 0) {
            if let days: String = logrecordssnapshot?[i].days {
                if Double(days) ?? 0 >= num {
                    j += 1
                }
            }
        }
        return j - 1
    }

    init(profile: String?,
         config: Configuration,
         configurations: RsyncUIconfigurations?,
         snapshotdata: SnapshotData)
    {
        super.init(config: config, snapshotdata: snapshotdata)
        // Getting log records from schedules, sorted after date
        logrecordssnapshot = LogRecords(hiddenID: config.hiddenID,
                                        profile: profile,
                                        configurations: configurations).loggrecordssnapshots
    }

    override func processtermination(data: [String]?) {
        prepareremotesnapshotcatalogs(data: data)
        calculateddayssincesynchronize()
        mergeremotecatalogsandlogs()
        mysnapshotdata?.state = .gotit
        // Getting data is completed
        mysnapshotdata?.snapshotlist = false
    }
}
