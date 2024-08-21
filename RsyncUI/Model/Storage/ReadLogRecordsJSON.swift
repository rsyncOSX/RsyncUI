//
//  ReadLogRecordsJSON.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 19/04/2021.
//
// swiftlint:disable line_length

import DecodeEncodeGeneric
import Foundation
import OSLog

@MainActor
final class ReadLogRecordsJSON: PropogateError {
    var logrecords: [LogRecords]?
    let path = Homepath()

    private func importjsonfile(_ filenamedatastore: String,
                                profile _: String?,
                                validhiddenID: Set<Int>)
    {
        let decodeimport = DecodeGeneric()
        do {
            if let data = try
                decodeimport.decodearraydatafileURL(DecodeLogRecords.self, fromwhere: filenamedatastore)
            {
                logrecords = [LogRecords]()
                for i in 0 ..< data.count {
                    let onerecords = LogRecords(data[i])
                    if validhiddenID.contains(onerecords.hiddenID) {
                        logrecords?.append(onerecords)
                    }
                }
                Logger.process.info("ReadLogRecordsJSON: read logrecords from permanent storage")
            }

        } catch let e {
            let error = e
            propogateerror(error: error)
        }
    }

    init(_ profile: String?, _ validhiddenID: Set<Int>) {
        var filename = ""
        if let profile, let path = path.fullpathmacserial {
            filename = path + "/" + profile + "/" + SharedReference.shared.filenamelogrecordsjson
        } else {
            if let path = path.fullpathmacserial {
                filename = path + "/" + SharedReference.shared.filenamelogrecordsjson
            }
        }
        importjsonfile(filename,
                       profile: profile,
                       validhiddenID: validhiddenID)
    }
}

// swiftlint:enable line_length
