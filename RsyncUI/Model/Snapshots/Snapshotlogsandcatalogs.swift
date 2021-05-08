//
//  SnapshotsLoggData.swift
//  RsyncOSX
//
//  Created by Thomas Evensen on 22.01.2018.
//  Copyright © 2018 Thomas Evensen. All rights reserved.
//

import Foundation

final class Snapshotlogsandcatalogs {
    // Number of local logrecords
    var logrecordssnapshot: [Logrecordsschedules]?
    var localeconfig: Configuration?
    var outputprocess: OutputfromProcess?
    var snapshotcatalogstodelete: [String]?
    var mysnapshotdata: SnapshotData?

    // Remote snapshot catalags
    typealias Catalogsanddates = (String, Date)
    var catalogsanddates: [Catalogsanddates]?
    // uuids and administrating snapshots, save tje UUID from the Log records.
    var uuidsLog: Set<UUID>?

    private func getremotecataloginfo() {
        outputprocess = OutputfromProcess()
        let arguments = RestorefilesArguments(task: .snapshotcatalogs,
                                              config: localeconfig,
                                              remoteFile: nil,
                                              localCatalog: nil,
                                              drynrun: nil)
        let command = RsyncProcessCmdCombineClosure(arguments: arguments.getArguments(),
                                                    config: nil,
                                                    processtermination: processtermination,
                                                    filehandler: filehandler)
        mysnapshotdata?.state = .getdata
        command.executeProcess(outputprocess: outputprocess)
    }

    // Getting, from process, remote snapshotcatalogs
    // sort snapshotcatalogs
    private func prepareremotesnapshotcatalogs() {
        // Check for split lines and merge lines if true
        let data = PrepareOutput(outputprocess?.getOutput() ?? [])
        if data.splitlines { data.alignsplitlines() }
        var catalogs = TrimOne(data.trimmeddata).trimmeddata
        var datescatalogs = TrimFour(data.trimmeddata).trimmeddata
        // drop index where row = "./."
        if let index = catalogs.firstIndex(where: { $0 == "./." }) {
            catalogs.remove(at: index)
            datescatalogs.remove(at: index)
        }
        catalogsanddates = [Catalogsanddates]()
        let dateformatter = DateFormatter()
        dateformatter.dateFormat = "YYYY/mm/dd"
        for i in 0 ..< catalogs.count {
            if let date = dateformatter.date(from: datescatalogs[i]) {
                catalogsanddates?.append((catalogs[i], date))
            }
        }
        catalogsanddates = catalogsanddates?.sorted { cat1, cat2 in
            (Int(cat1.0.dropFirst(2)) ?? 0) > (Int(cat2.0.dropFirst(2)) ?? 0)
        }
        // Set number of remote catalogs
        mysnapshotdata?.numremotecatalogs = catalogsanddates?.count ?? 0
    }

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
        var adjustedlogrecords = [Logrecordsschedules]()
        let logcount = logrecordssnapshot?.count ?? 0
        // Set number of local logrecords
        mysnapshotdata?.numlocallogrecords = logcount
        let mycatalogs = catalogsanddates
        var mylogrecords = logrecordssnapshot
        // Loop through all real catalogs, find the corresponding logrecord if any
        // and add the adjusted record
        for i in 0 ..< (mycatalogs?.count ?? 0) {
            // Real snapshotcatalog collected from remote and
            // drop the "./" and add "(" and ")" before filter
            let realsnapshotcatalog = "(" + (mycatalogs?[i].0 ?? "").dropFirst(2) + ")"
            let record = mylogrecords?.filter { $0.resultExecuted.contains(realsnapshotcatalog.dropFirst(2)) }
            // Found one record
            if record?.count ?? 0 > 0 {
                if var record = record?[0] {
                    let catalogelementlog = record.resultExecuted.split(separator: " ")[0]
                    let snapshotcatalogfromschedulelog = "./" + catalogelementlog.dropFirst().dropLast()
                    let uuid = record.id
                    record.period = "... not yet tagged ..."
                    record.snapshotCatalog = snapshotcatalogfromschedulelog
                    adjustedlogrecords.append(record)
                    // Remove uudid which are matcing
                    if let idLog = record.idLog {
                        uuidsLog?.remove(idLog)
                    }
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
    }

    func calculatedays(datestringlocalized: String) -> Double? {
        guard datestringlocalized != "" else { return nil }
        let lastbackup = datestringlocalized.localized_date_from_string()
        let seconds: TimeInterval = lastbackup.timeIntervalSinceNow
        return seconds * (-1)
    }

    func countbydays(num: Double) -> Int {
        guard logrecordssnapshot?.count ?? 0 > 0 else { return 0 }
        var j: Int = 0
        for i in 0 ..< (logrecordssnapshot?.count ?? 0) - 1 {
            if let days: String = logrecordssnapshot?[i].days {
                if Double(days) ?? 0 >= num {
                    j += 1
                }
            }
        }
        return j - 1
    }

    init(config: Configuration,
         configurationsSwiftUI: ConfigurationsSwiftUI?,
         schedulesSwiftUI: SchedulesSwiftUI?,
         snapshotdata: SnapshotData)
    {
        guard config.task == SharedReference.shared.snapshot else { return }
        localeconfig = config
        mysnapshotdata = snapshotdata
        // Getting log records from schedules, sorted after date
        var alllogs: AllLoggs? = AllLoggs(hiddenID: config.hiddenID,
                                          configurationsSwiftUI: configurationsSwiftUI,
                                          schedulesSwiftUI: schedulesSwiftUI)
        logrecordssnapshot = alllogs?.loggrecords
        uuidsLog = alllogs?.uuidsLog
        // release the object - dont need it more
        alllogs = nil
        // Getting remote catalogdata about all snapshots
        getremotecataloginfo()
    }

    deinit {
        // print("deinit Snapshotlogsandcatalogs")
    }
}

extension Snapshotlogsandcatalogs {
    func processtermination() {
        prepareremotesnapshotcatalogs()
        calculateddayssincesynchronize()
        mergeremotecatalogsandlogs()
        mysnapshotdata?.state = .gotit
        mysnapshotdata?.uuidsLog = uuidsLog
    }

    func filehandler() {}
}
