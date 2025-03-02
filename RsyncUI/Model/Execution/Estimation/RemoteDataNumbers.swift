//
//  RemoteDataNumbers.swift
//  RsyncOSX
//
//  Created by Thomas Evensen on 31.12.2017.
//  Copyright © 2017 Thomas Evensen. All rights reserved.
//
// swiftlint:disable line_length

import Foundation
import OSLog
import ParseRsyncOutput

@MainActor
struct RemoteDataNumbers: Identifiable, Hashable {
    var id: SynchronizeConfiguration.ID
    var hiddenID: Int = -1
    var transferredNumber: String = ""
    var transferredNumber_Int: Int = 0
    var transferredNumberSizebytes_Int: Int = 0
    var totalNumber: String = ""
    var totalNumberSizebytes: String = ""
    var totalNumberSizebytes_Int: Int = 0
    var totalDirs: String = ""
    var totalDirs_Int: Int = 0
    var newfiles: String = ""
    var newfiles_Int: Int = 0
    var deletefiles: String = ""
    var deletefiles_Int: Int = 0
    var totalNumber_totalDirs: String = ""

    var task: String = ""
    var localCatalog: String = ""
    var offsiteCatalog: String = ""
    var offsiteServer: String = ""
    var backupID: String = ""

    // Detailed output used in Views
    var outputfromrsync: [RsyncOutputData]?
    // True if data to synchronize
    var datatosynchronize: Bool = false
    // Ask if synchronizing so much data
    // is true or not. If not either yes,
    // new task or no if like server is not
    // online.
    var confirmsynchronize: Bool = false
    // Summarized stats
    var stats: String?

    init(stringoutputfromrsync: [String]?,
         config: SynchronizeConfiguration?)
    {
        hiddenID = config?.hiddenID ?? -1
        task = config?.task ?? ""
        localCatalog = config?.localCatalog ?? ""
        offsiteServer = config?.offsiteServer ?? "localhost"
        offsiteCatalog = config?.offsiteCatalog ?? ""
        backupID = config?.backupID ?? "Synchronize ID"
        id = config?.id ?? UUID()

        Logger.process.info("RemoteDataNumbers: adjusted output from rsync: \(stringoutputfromrsync?.count ?? 0) rows")

        // Prepareoutput prepares output from rsync for extracting the numbers only.
        // It removes all lines except the last 20 lines where summarized numbers are put
        let preparedoutputfromrsync = PrepareOutputFromRsync().prepareOutputFromRsync(stringoutputfromrsync)
        if preparedoutputfromrsync.count > 0 {
            let parsersyncoutput = ParseRsyncOutput(preparedoutputfromrsync,
                                                    SharedReference.shared.rsyncversion3)
            stats = parsersyncoutput.stats
            transferredNumber = parsersyncoutput.formatted_filestransferred
            transferredNumber_Int = parsersyncoutput.numbersonly?.filestransferred ?? 0
            
            totalDirs_Int = parsersyncoutput.numbersonly?.totaldirectories ?? 0
            transferredNumberSizebytes_Int = Int(parsersyncoutput.numbersonly?.totaltransferredfilessize ?? 0)
            
            totalNumber = parsersyncoutput.formatted_numberoffiles
            totalNumber_totalDirs = parsersyncoutput.formatted_numberoffiles
            
            totalNumberSizebytes = parsersyncoutput.formatted_totalfilesize
            totalNumberSizebytes_Int = Int(parsersyncoutput.numbersonly?.totalfilesize ?? 0)
            
            totalDirs = parsersyncoutput.formatted_totaldirectories
            
            newfiles = parsersyncoutput.formatted_numberofcreatedfiles
            newfiles_Int = parsersyncoutput.numbersonly?.numberofcreatedfiles ?? 0
            deletefiles = parsersyncoutput.formatted_numberofdeletedfiles
            deletefiles_Int = parsersyncoutput.numbersonly?.numberofdeletedfiles ?? 0

            if Int(transferredNumber) ?? 0 > 0 || Int(deletefiles) ?? 0 > 0 {
                datatosynchronize = true
            } else {
                datatosynchronize = false
            }
            if SharedReference.shared.rsyncversion3,
               transferredNumber_Int + totalDirs_Int == newfiles_Int
            {
                confirmsynchronize = true
                Logger.process.info("RemoteDataNumbers: confirmsynchronize - TRUE")
            } else {
                Logger.process.info("RemoteDataNumbers: confirmsynchronize - FALSE")
            }
        }
    }
}

// swiftlint:enable line_length
