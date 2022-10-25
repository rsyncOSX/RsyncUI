//
//  RemoteInfoTask.swift
//  RsyncOSX
//
//  Created by Thomas Evensen on 31.12.2017.
//  Copyright © 2017 Thomas Evensen. All rights reserved.
//
// swiftlint:disable line_length

import Foundation

struct RemoteinfonumbersOnetask: Identifiable, Hashable {
    var id: Int
    var hiddenID: Int
    var transferredNumber: String
    var transferredNumberSizebytes: String
    var totalNumber: String
    var totalNumberSizebytes: String
    var totalDirs: String
    var newfiles: String
    var deletefiles: String
    var selected = 0
    var config: Configuration?

    init(hiddenID: Int?,
         outputfromrsync: [String]?,
         config: Configuration?)
    {
        self.hiddenID = hiddenID ?? -1
        self.config = config
        let number = Numbers(outputfromrsync ?? [])
        transferredNumber = NumberFormatter.localizedString(from: NSNumber(value: number.getTransferredNumbers(numbers: .transferredNumber)), number: NumberFormatter.Style.none)
        transferredNumberSizebytes = NumberFormatter.localizedString(from: NSNumber(value: number.getTransferredNumbers(numbers: .transferredNumberSizebytes)), number: NumberFormatter.Style.decimal)
        totalNumber = NumberFormatter.localizedString(from: NSNumber(value: number.getTransferredNumbers(numbers: .totalNumber)), number: NumberFormatter.Style.decimal)
        totalNumberSizebytes = NumberFormatter.localizedString(from: NSNumber(value: number.getTransferredNumbers(numbers: .totalNumberSizebytes)), number: NumberFormatter.Style.decimal)
        totalDirs = NumberFormatter.localizedString(from: NSNumber(value: number.getTransferredNumbers(numbers: .totalDirs)), number: NumberFormatter.Style.decimal)
        newfiles = NumberFormatter.localizedString(from: NSNumber(value: number.getTransferredNumbers(numbers: .new)), number: NumberFormatter.Style.none)
        deletefiles = NumberFormatter.localizedString(from: NSNumber(value: number.getTransferredNumbers(numbers: .delete)), number: NumberFormatter.Style.none)
        id = hiddenID ?? -1
    }
}
