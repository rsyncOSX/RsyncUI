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
            if let record = mylogrecords?.filter({ $0.resultExecuted.contains(realsnapshotcatalog) }), record.count == 1 {
                let catalogelementlog = record[0].resultExecuted.split(separator: " ")[0]
                let snapshotcatalogfromschedulelog = "./" + catalogelementlog.dropFirst().dropLast()
                var item = record[0]
                item.period = "... no tag ..."
                item.snapshotCatalog = snapshotcatalogfromschedulelog
                adjustedlogrecords.append(item)
            } else {
                var item = LogRecordSnapshot(date: Date(), dateExecuted: "no record", resultExecuted: "no record")
                let snapshotcatalogfromschedulelog = "./" + realsnapshotcatalog.dropFirst().dropLast()
                item.period = "... no tag ..."
                item.snapshotCatalog = snapshotcatalogfromschedulelog
                adjustedlogrecords.append(item)
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
            let catalogs = TrimOutputForRestore(stringoutputfromrsync).trimmeddata
            catalogsanddates = catalogs?.compactMap { line in
                let item = Catalogsanddates(catalog: line)
                return (line.contains("done") == false && line.contains("receiving") == false &&
                        line.contains("sent") == false && line.contains("total") == false &&
                        line.contains("./.") == false && line.isEmpty == false &&
                        line.contains("speedup") == false && line.contains("bytes") == false) ? item : nil
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
