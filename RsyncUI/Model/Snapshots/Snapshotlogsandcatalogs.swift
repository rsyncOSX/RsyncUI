//
//  Snapshotlogsandcatalogs.swift
//  RsyncOSX
//
//  Created by Thomas Evensen on 22.01.2018.
//  Copyright © 2018 Thomas Evensen. All rights reserved.
//

import Foundation

@MainActor
final class Snapshotlogsandcatalogs {
    // Number of local logrecords
    var logrecordssnapshot: [LogRecordSnapshot]?
    var catalogsanddates: [Catalogsanddates]?
    var mysnapshotdata: SnapshotData?

    func getremotecataloginfo(_ config: SynchronizeConfiguration) {
        let arguments = ArgumentsSnapshotRemoteCatalogs(config: config).remotefilelistarguments()
        let command = ProcessRsync(arguments: arguments,
                                   processtermination: processtermination)
        command.executeProcess()
    }

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
        var adjustedlogrecords = [LogRecordSnapshot]()
        let mycatalogs = catalogsanddates
        let mylogrecords = logrecordssnapshot
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
                    record.period = "... no tag ..."
                    record.snapshotCatalog = snapshotcatalogfromschedulelog
                    adjustedlogrecords.append(record)
                }
            } else {
                var record = LogRecordSnapshot(date: Date(), dateExecuted: "no record", resultExecuted: "no record")
                let snapshotcatalogfromschedulelog = "./" + realsnapshotcatalog.dropFirst().dropLast()
                record.period = "... no tag ..."
                record.snapshotCatalog = snapshotcatalogfromschedulelog
                adjustedlogrecords.append(record)
            }
        }
        mysnapshotdata?.setsnapshotdata(adjustedlogrecords)
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
        guard config.task == SharedReference.shared.snapshot else { return }
        mysnapshotdata = snapshotdata
        getremotecataloginfo(config)
        // Getting log records, sorted after date
        logrecordssnapshot = RecordsSnapshot(config: config, logrecords: logrecords).loggrecordssnapshots
    }

    func processtermination(stringoutputfromrsync: [String]?, hiddenID _: Int?) {
        if let stringoutputfromrsync {
            var catalogs = TrimOutputForRestore(stringoutputfromrsync).trimmeddata

            if let index = catalogs.firstIndex(where: { $0 == "./done" }) {
                catalogs.remove(at: index)
            }
            if let index = catalogs.firstIndex(where: { $0 == "./." }) {
                catalogs.remove(at: index)
            }

            catalogsanddates = catalogs.map { line in
                Catalogsanddates(catalog: line)
            }.sorted { cat1, cat2 in
                (Int(cat1.catalog.dropFirst(2)) ?? 0) > (Int(cat2.catalog.dropFirst(2)) ?? 0)
            }
        }
        mysnapshotdata?.catalogsanddates = catalogsanddates ?? []
        calculateddayssincesynchronize()
        mergeremotecatalogsandlogs()
        // Getting data is completed
        mysnapshotdata?.snapshotlist = false
    }
}

/*
 // A split of lines are always after each other.
 // Line length is about 48/49 characters, a split might be like
 // drwx------             71 2019/07/02 07:53:37 300
 // drwx------             71 2019/07/02 07:53:37 30
 // 1
 // drwx------             72 2019/07/05 09:35:31 302
 //
 func alignsplitlines() {
     for i in 0 ..< trimmeddata.count - 1 {
         guard i < (trimmeddata.count - 1) else { return }
         if trimmeddata[i].count < 40, i > 0 {
             // Must decide which two lines to merge
             if trimmeddata[i - 1].count > trimmeddata[i + 1].count {
                 // Merge i and i+1, remove i+1
                 let newline = trimmeddata[i] + trimmeddata[i + 1]
                 trimmeddata[i] = newline
                 trimmeddata.remove(at: i + 1)
             } else {
                 let newline = trimmeddata[i - 1] + trimmeddata[i]
                 trimmeddata[i - 1] = newline
                 trimmeddata.remove(at: i)
             }
         }
     }
 }
 */
