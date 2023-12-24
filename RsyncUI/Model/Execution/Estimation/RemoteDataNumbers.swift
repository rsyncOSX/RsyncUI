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
    var id: Configuration.ID
    var hiddenID: Int
    var transferredNumber: String
    var transferredNumberSizebytes: String
    var totalNumber: String
    var totalNumberSizebytes: String
    var totalDirs: String
    var newfiles: String
    var deletefiles: String
    var config: Configuration?

    var task: String
    var localCatalog: String
    var offsiteCatalog: String
    var offsiteUsername: String
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

    init(hiddenID: Int?,
         outputfromrsync: [String]?,
         config: Configuration?)
    {
        self.hiddenID = hiddenID ?? -1
        self.config = config
        self.outputfromrsync = outputfromrsync
        task = config?.task ?? ""
        localCatalog = config?.localCatalog ?? ""
        offsiteServer = config?.offsiteServer ?? "localhost"
        offsiteUsername = config?.offsiteUsername ?? "localuser"
        offsiteCatalog = config?.offsiteCatalog ?? ""
        backupID = config?.backupID ?? "Synchronize ID"
        let number = Numbers(outputfromrsync ?? [])
        transferredNumber = NumberFormatter.localizedString(from: NSNumber(value: number.getTransferredNumbers(numbers: .transferredNumber)), number: NumberFormatter.Style.none)
        transferredNumberSizebytes = NumberFormatter.localizedString(from: NSNumber(value: number.getTransferredNumbers(numbers: .transferredNumberSizebytes)), number: NumberFormatter.Style.decimal)
        totalNumber = NumberFormatter.localizedString(from: NSNumber(value: number.getTransferredNumbers(numbers: .totalNumber)), number: NumberFormatter.Style.decimal)
        totalNumberSizebytes = NumberFormatter.localizedString(from: NSNumber(value: number.getTransferredNumbers(numbers: .totalNumberSizebytes)), number: NumberFormatter.Style.decimal)
        totalDirs = NumberFormatter.localizedString(from: NSNumber(value: number.getTransferredNumbers(numbers: .totalDirs)), number: NumberFormatter.Style.decimal)
        newfiles = NumberFormatter.localizedString(from: NSNumber(value: number.getTransferredNumbers(numbers: .new)), number: NumberFormatter.Style.none)
        deletefiles = NumberFormatter.localizedString(from: NSNumber(value: number.getTransferredNumbers(numbers: .delete)), number: NumberFormatter.Style.none)
        id = config?.id ?? UUID()
        if Int(transferredNumber) ?? 0 > 0 || Int(deletefiles) ?? 0 > 0 {
            datatosynchronize = true
        } else {
            datatosynchronize = false
        }
        if totalNumber == "0", deletefiles == "0",
           (outputfromrsync?.count ?? 0) - (Int(newfiles) ?? 0) < 30
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
