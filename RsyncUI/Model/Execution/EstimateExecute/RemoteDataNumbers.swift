//
//  RemoteDataNumbers.swift
//  RsyncUI
//

import Foundation
import OSLog
import ParseRsyncOutput

@MainActor
struct RemoteDataNumbers: Identifiable, Hashable {
    var id: SynchronizeConfiguration.ID
    var hiddenID: Int = -1
    var filestransferred: String = ""
    var filestransferredInt: Int = 0
    var totaltransferredfilessizeInt: Int = 0
    var totaltransferredfilessize: String = ""
    var numberoffiles: String = ""
    var totalfilesize: String = ""
    var totalfilesizeInt: Int = 0
    var totaldirectories: String = ""
    var totaldirectoriesInt: Int = 0
    var newfiles: String = ""
    var newfilesInt: Int = 0
    var deletefiles: String = ""
    var deletefilesInt: Int = 0

    var totalnumbers: String = ""

    var task: String = ""
    var localCatalog: String = ""
    var offsiteCatalog: String = ""
    var offsiteServer: String = ""
    var backupID: String = ""

    // Detailed output used in Views, allocated as part of process termination estimate
    var outputfromrsync: [RsyncOutputData]?
    // True if data to synchronize
    var datatosynchronize: Bool = false
    // Ask if synchronizing so much data
    // is true or not. If not either yes,
    // new task or no if like server is not
    // online.
    var confirmexecute: Bool = false
    // Summarized stats
    var stats: String?
    // A reduced number of output
    var preparedoutputfromrsync: [String]?
    // Number of lines in output to handle
    let numberoflines = 20

    // True if the two following arguments for rsync is present
    // - `--itemize-changes` - output change-summary for all updates
    // - `--update` - evaluates the timestamp
    var itemizechanges: Bool = false

    private mutating func defaultvalues() {
        let defaultstats = "0 files : 0.00 MB in 0.00 seconds"
        // Break this loop, the numbers below make no sense if stats is missing
        stats = defaultstats
        filestransferred = "No stats"
        filestransferredInt = 0
        totaldirectoriesInt = 0
        newfilesInt = 0
        deletefilesInt = 0
        totaltransferredfilessizeInt = 0
        totalfilesizeInt = 0
        numberoffiles = "0"
        totalfilesize = "0"
        totaldirectories = "0"
        newfiles = "0"
        deletefiles = "0"
        totalnumbers = "0"
        datatosynchronize = false
        Logger.process.debugMessageOnly("RemoteDataNumbers: getstats() FAILED")
    }

    init(stringoutputfromrsync: [String]?,
         config: SynchronizeConfiguration?) {
        if let hiddenID = config?.hiddenID {
            self.hiddenID = hiddenID
        }
        task = config?.task ?? ""
        localCatalog = config?.localCatalog ?? ""
        offsiteServer = config?.offsiteServer ?? "localhost"
        offsiteCatalog = config?.offsiteCatalog ?? ""
        backupID = config?.backupID ?? "Synchronize ID"
        id = config?.id ?? UUID()

        // Prepareoutput prepares output from rsync for extracting the numbers only.
        // It removes all lines except the last 20 lines where summarized numbers are put
        // Normally this is done before calling the RemoteDataNumbers

        if stringoutputfromrsync?.count ?? 0 > numberoflines {
            preparedoutputfromrsync = PrepareOutputFromRsync().prepareOutputFromRsync(stringoutputfromrsync)
        } else {
            preparedoutputfromrsync = stringoutputfromrsync
        }
        if let preparedoutputfromrsync, preparedoutputfromrsync.count > 0 {
            let parsersyncoutput = ParseRsyncOutput(preparedoutputfromrsync,
                                                    SharedReference.shared.rsyncversion3 ? .ver3 : .openrsync)
            do {
                stats = try parsersyncoutput.getstats()
                Logger.process.debugMessageOnly("RemoteDataNumbers: getstats() SUCCESS")
            } catch let err {
                if SharedReference.shared.silencemissingstats == false {
                    let error = err
                    SharedReference.shared.errorobject?.alert(error: error)
                } else {
                    // Break this loop, the numbers below make no sense if stats is missing
                    defaultvalues()
                    return
                }
            }

            filestransferred = parsersyncoutput.formatted_filestransferred
            filestransferredInt = parsersyncoutput.numbersonly?.filestransferred ?? 0
            totaldirectoriesInt = parsersyncoutput.numbersonly?.totaldirectories ?? 0
            newfilesInt = parsersyncoutput.numbersonly?.numberofcreatedfiles ?? 0
            deletefilesInt = parsersyncoutput.numbersonly?.numberofdeletedfiles ?? 0
            totaltransferredfilessizeInt = Int(parsersyncoutput.numbersonly?.totaltransferredfilessize ?? 0)
            totaltransferredfilessize = parsersyncoutput.formatted_totaltransferredfilessize
            totalfilesizeInt = Int(parsersyncoutput.numbersonly?.totalfilesize ?? 0)
            numberoffiles = parsersyncoutput.formatted_numberoffiles
            totalfilesize = parsersyncoutput.formatted_totalfilesize
            totaldirectories = parsersyncoutput.formatted_totaldirectories
            newfiles = parsersyncoutput.formatted_numberofcreatedfiles
            deletefiles = parsersyncoutput.formatted_numberofdeletedfiles
            totalnumbers = parsersyncoutput.formatted_numberoffiles_totaldirectories
            datatosynchronize = parsersyncoutput.numbersonly?.datatosynchronize ?? true

            if SharedReference.shared.rsyncversion3,
               filestransferredInt + totaldirectoriesInt == newfilesInt,
               datatosynchronize {
                confirmexecute = true
            }
        }
    }
}
