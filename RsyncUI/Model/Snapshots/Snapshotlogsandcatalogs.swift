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
    var outputprocess: OutputProcess?
    var snapshotcatalogstodelete: [String]?
    var mysnapshotdata: SnapshotData?

    // Remote snapshot catalags
    typealias Catalogsanddates = (String, Date)
    var catalogsanddates: [Catalogsanddates]?
    // uuids and administrating snapshots, save tje UUID from the Log records.
    var uuidsLog: Set<UUID>?

    private func getremotecataloginfo() {
        outputprocess = OutputProcess()
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
        if let catalogs = outputprocess?.trimoutput(trim: .one),
           let datescatalogs = outputprocess?.trimoutput(trim: .four)
        {
            catalogsanddates = [Catalogsanddates]()
            let dateformatter = DateFormatter()
            dateformatter.dateFormat = "YYYY/mm/dd"
            for i in 0 ..< catalogs.count where i < datescatalogs.count {
                if let date = dateformatter.date(from: datescatalogs[i]) {
                    if catalogs[i].contains("./.") == false {
                        self.catalogsanddates?.append((catalogs[i], date))
                    }
                }
            }
        }
        catalogsanddates = catalogsanddates?.sorted { cat1, cat2 in
            let nr1 = Int(cat1.0.dropFirst(2)) ?? 0
            let nr2 = Int(cat2.0.dropFirst(2)) ?? 0
            if nr1 > nr2 {
                return true
            } else {
                return false
            }
        }
        // Set number of remote catalogs
        mysnapshotdata?.numremotecatalogs = catalogsanddates?.count ?? 0
        print("remotecatalogs \(mysnapshotdata?.numremotecatalogs ?? 0)")
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
        print("logrecords \(mysnapshotdata?.numlocallogrecords ?? 0)")
        for i in 0 ..< (catalogsanddates?.count ?? 0) {
            var j = 0
            if let logrecordssnapshot = self.logrecordssnapshot {
                if logrecordssnapshot.contains(where: { record in
                    let catalogelementlog = record.resultExecuted.split(separator: " ")[0]
                    let snapshotcatalogfromschedulelog = "./" + catalogelementlog.dropFirst().dropLast()
                    if snapshotcatalogfromschedulelog == self.catalogsanddates?[i].0 {
                        if j < logcount {
                            self.logrecordssnapshot?[j].period = "... not yet tagged ..."
                            self.logrecordssnapshot?[j].snapshotCatalog = snapshotcatalogfromschedulelog
                            if let record = self.logrecordssnapshot?[j] {
                                adjustedlogrecords.append(record)
                                // Remove ids which are matcing
                                if let idLog = record.idLog {
                                    uuidsLog?.remove(idLog)
                                }
                            }
                        }
                        j += 1
                        return true
                    }
                    j += 1
                    return false
                }) {}
            }
        }
        logrecordssnapshot = adjustedlogrecords.sorted { cat1, cat2 -> Bool in
            if let cat1 = cat1.snapshotCatalog,
               let cat2 = cat2.snapshotCatalog
            {
                let nr1 = Int(cat1.dropFirst(2)) ?? 0
                let nr2 = Int(cat2.dropFirst(2)) ?? 0
                if nr1 > nr2 {
                    return true
                } else {
                    return false
                }
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
        print("uuids \(mysnapshotdata?.uuidsLog?.count ?? 0)")
    }

    func filehandler() {}
}
