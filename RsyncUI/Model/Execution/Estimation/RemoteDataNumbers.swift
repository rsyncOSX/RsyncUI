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

struct RemoteDataNumbers: Identifiable, Hashable {
    var id: SynchronizeConfiguration.ID
    var hiddenID: Int
    var transferredNumber: String
    var transferredNumber_Int: Int
    var transferredNumberSizebytes: String
    var transferredNumberSizebytes_Int: Int
    var totalNumber: String
    var totalNumberSizebytes: String
    var totalNumberSizebytes_Int: Int
    var totalDirs: String
    var totalDirs_Int: Int
    var newfiles: String
    var newfiles_Int: Int
    var deletefiles: String
    var deletefiles_Int: Int
    var totalNumber_totalDirs: String

    var task: String
    var localCatalog: String
    var offsiteCatalog: String
    var offsiteServer: String
    var backupID: String

    // Detailed output
    var outputfromrsync: [String]?
    // True if data to synchronize
    var datatosynchronize: Bool
    // Ask if synchronizing so much data
    // is true or not. If not either yes,
    // new task or no if like server is not
    // online.
    var confirmsynchronize: Bool

    @MainActor
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
        let number = Numbers(outputfromrsync ?? [])
        transferredNumber = NumberFormatter.localizedString(from: NSNumber(value: number.getTransferredNumbers(numbers: .transferredNumber)), number: NumberFormatter.Style.none)
        transferredNumber_Int = number.getTransferredNumbers(numbers: .transferredNumber)
        totalDirs_Int = number.getTransferredNumbers(numbers: .totalDirs)
        transferredNumberSizebytes = NumberFormatter.localizedString(from: NSNumber(value: number.getTransferredNumbers(numbers: .transferredNumberSizebytes)), number: NumberFormatter.Style.decimal)
        transferredNumberSizebytes_Int = number.getTransferredNumbers(numbers: .transferredNumberSizebytes)
        totalNumber = NumberFormatter.localizedString(from: NSNumber(value: number.getTransferredNumbers(numbers: .totalNumber)), number: NumberFormatter.Style.decimal)
        totalNumberSizebytes = NumberFormatter.localizedString(from: NSNumber(value: number.getTransferredNumbers(numbers: .totalNumberSizebytes)), number: NumberFormatter.Style.decimal)
        totalNumberSizebytes_Int = number.getTransferredNumbers(numbers: .totalNumberSizebytes)
        totalDirs = NumberFormatter.localizedString(from: NSNumber(value: number.getTransferredNumbers(numbers: .totalDirs)), number: NumberFormatter.Style.decimal)
        totalNumber_totalDirs = NumberFormatter.localizedString(from: NSNumber(value: number.getTransferredNumbers(numbers: .totalNumber_totalDirs)), number: NumberFormatter.Style.decimal)
        newfiles = NumberFormatter.localizedString(from: NSNumber(value: number.getTransferredNumbers(numbers: .new)), number: NumberFormatter.Style.none)
        newfiles_Int = number.getTransferredNumbers(numbers: .new)
        deletefiles = NumberFormatter.localizedString(from: NSNumber(value: number.getTransferredNumbers(numbers: .delete)), number: NumberFormatter.Style.none)
        deletefiles_Int = number.getTransferredNumbers(numbers: .delete)
        id = config?.id ?? UUID()
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
            confirmsynchronize = false
            Logger.process.info("RemoteDataNumbers: confirmsynchronize - FALSE")
        }
    }
}

// swiftlint:enable line_length
