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
final class ReadLogRecordsJSON {
    func readjsonfilelogrecords(_ profile: String?, _ validhiddenIDs: Set<Int>) -> [LogRecords]? {
        var filename = ""
        let path = Homepath()

        if let profile, let path = path.fullpathmacserial {
            filename = path + "/" + profile + "/" + SharedConstants().filenamelogrecordsjson
        } else {
            if let path = path.fullpathmacserial {
                filename = path + "/" + SharedConstants().filenamelogrecordsjson
            }
        }
        let decodeimport = DecodeGeneric()
        do {
            if let data = try
                decodeimport.decodearraydatafileURL(DecodeLogRecords.self, fromwhere: filename)
            {
                Logger.process.info("ReadLogRecordsJSON - \(profile ?? "default profile", privacy: .public): read logrecords from permanent storage")
                return data.compactMap { element in
                    let item = LogRecords(element)
                    return validhiddenIDs.contains(item.hiddenID) ? item : nil
                }
            }

        } catch let e {
            Logger.process.error("ReadLogRecordsJSON - \(profile ?? "default profile", privacy: .public): some ERROR reading logrecords from permanent storage")
            let error = e
            path.propogateerror(error: error)
        }
        return nil
    }

    deinit {
        Logger.process.info("ReadLogRecordsJSON: deinit")
    }
}
