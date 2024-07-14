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
    var logrecordssnapshot: [SnapshotLogRecords]?

    // Calculating days since snaphot was executed
    private func calculateddayssincesynchronize() {
        for i in 0 ..< (logrecordssnapshot?.count ?? 0) {
            if let dateRun = logrecordssnapshot?[i].dateExecuted {
                if let secondssince = calculatedays(datestringlocalized: dateRun) {
                    logrecordssnapshot?[i].days = String(format: "%.2f", secondssince / (60 * 60 * 24))
                }
            }
        }
    }

    // Merging remote snaphotcatalogs and existing logs
    private func mergeremotecatalogsandlogs() {
        var adjustedlogrecords = [SnapshotLogRecords]()
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
        // Add records for use in the View
        mysnapshotdata?.setsnapshotdata(logrecordssnapshot)
        guard logrecordssnapshot?.count ?? 0 > 0 else { return }
    }

    func calculatedays(datestringlocalized: String) -> Double? {
        guard datestringlocalized != "" else { return nil }
        let lastbackup = datestringlocalized.localized_date_from_string()
        let seconds: TimeInterval = lastbackup.timeIntervalSinceNow
        return seconds * -1
    }

    init(config: SynchronizeConfiguration,
         logrecords: [LogRecords],
         snapshotdata: SnapshotData)
    {
        super.init(config: config, snapshotdata: snapshotdata)
        // Getting log records, sorted after date
        logrecordssnapshot = SnapshotRecords(config: config, logrecords: logrecords).loggrecordssnapshots
    }

    override func processtermination(data: [String]?, hiddenID _: Int?) {
        prepareremotesnapshotcatalogs(data: data)
        calculateddayssincesynchronize()
        mergeremotecatalogsandlogs()
        // Getting data is completed
        mysnapshotdata?.snapshotlist = false
    }
}
