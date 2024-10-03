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
    var hiddenID: Int
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

    // Detailed output
    var outputfromrsync: [String]?
    // True if data to synchronize
    var datatosynchronize: Bool = false
    // Ask if synchronizing so much data
    // is true or not. If not either yes,
    // new task or no if like server is not
    // online.
    var confirmsynchronize: Bool = false
    // Summarized stats
    var stats: String?

    init(outputfromrsync: [String]?,
         config: SynchronizeConfiguration?)
    {
        self.outputfromrsync = outputfromrsync
        hiddenID = config?.hiddenID ?? -1
        task = config?.task ?? ""
        localCatalog = config?.localCatalog ?? ""
        offsiteServer = config?.offsiteServer ?? "localhost"
        offsiteCatalog = config?.offsiteCatalog ?? ""
        backupID = config?.backupID ?? "Synchronize ID"
        id = config?.id ?? UUID()

        if let outputfromrsync, outputfromrsync.count > 0 {
            let parsersyncoutput = ParseRsyncOutput(outputfromrsync,
                                                    SharedReference.shared.rsyncversion3)
            stats = parsersyncoutput.stats
            transferredNumber = parsersyncoutput.formatted_transferredNumber
            transferredNumber_Int = parsersyncoutput.numbersonly?.transferNum ?? 0
            totalDirs_Int = parsersyncoutput.numbersonly?.totDir ?? 0
            transferredNumberSizebytes_Int = Int(parsersyncoutput.numbersonly?.transferNumSize ?? 0)
            totalNumber = parsersyncoutput.formatted_totalNumber
            totalNumberSizebytes = parsersyncoutput.formatted_totalNumberSizebytes
            totalNumberSizebytes_Int = Int(parsersyncoutput.numbersonly?.transferNumSize ?? 0)
            totalDirs = parsersyncoutput.formatted_totalDirs
            totalNumber_totalDirs = parsersyncoutput.formatted_totalNumber
            newfiles = parsersyncoutput.formatted_newfiles
            newfiles_Int = parsersyncoutput.numbersonly?.newfiles ?? 0
            deletefiles = parsersyncoutput.formatted_deletefiles
            deletefiles_Int = parsersyncoutput.numbersonly?.deletefiles ?? 0

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
