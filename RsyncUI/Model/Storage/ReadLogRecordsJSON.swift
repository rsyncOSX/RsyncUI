//
//  ReadLogRecordsJSON.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 19/04/2021.
//

import DecodeEncodeGeneric
import Foundation
import OSLog

@MainActor
final class ReadLogRecordsJSON: PropogateError {
    var logrecords: [LogRecords]?
    let path = Homepath()
    var validhiddenIDs: Set<Int>?

    private func importjsonfile(_ filenamedatastore: String) {
        let decodeimport = DecodeGeneric()
        do {
            if let data = try
                decodeimport.decodearraydatafileURL(DecodeLogRecords.self, fromwhere: filenamedatastore)
            {
                if let validhiddenIDs {
                    logrecords = data.compactMap { element in
                        let item = LogRecords(element)
                        return validhiddenIDs.contains(item.hiddenID) ? item : nil
                    }
                }

                Logger.process.info("ReadLogRecordsJSON: read logrecords from permanent storage")
            }

        } catch let e {
            let error = e
            propogateerror(error: error)
        }
    }

    init(_ profile: String?,
         _ validhiddenIDs: Set<Int>?)
    {
        var filename = ""
        self.validhiddenIDs = validhiddenIDs
        if let profile, let path = path.fullpathmacserial {
            filename = path + "/" + profile + "/" + SharedReference.shared.filenamelogrecordsjson
        } else {
            if let path = path.fullpathmacserial {
                filename = path + "/" + SharedReference.shared.filenamelogrecordsjson
            }
        }
        importjsonfile(filename)
    }

    deinit {
        Logger.process.info("ReadLogRecordsJSON: deinit")
    }
}
