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

        if let profile, let fullpathmacserial = path.fullpathmacserial {
            filename = fullpathmacserial.appending("/") + profile.appending("/") + SharedConstants().filenamelogrecordsjson
        } else {
            if let fullpathmacserial = path.fullpathmacserial {
                filename = fullpathmacserial.appending("/") + SharedConstants().filenamelogrecordsjson
            }
        }
        let decodeimport = DecodeGeneric()
        do {
            let data = try
                decodeimport.decodeArray(DecodeLogRecords.self, fromFile: filename)

            Logger.process.debugmessageonly("ReadLogRecordsJSON - \(profile ?? "default") read logrecords from permanent storage")
            return data.compactMap { element in
                let item = LogRecords(element)
                return validhiddenIDs.contains(item.hiddenID) ? item : nil
            }

        } catch {
            Logger.process.error("ReadLogRecordsJSON - \(profile ?? "default profile", privacy: .public): some ERROR reading logrecords from permanent storage")
        }
        /*
         } catch let e {
             Logger.process.error("ReadLogRecordsJSON - \(profile ?? "default profile", privacy: .public): some ERROR reading logrecords from permanent storage")
             let error = e
             path.propagateError(error: error)
         }
          */
        return nil
    }

    deinit {
        Logger.process.debugmessageonly("ReadLogRecordsJSON: DEINIT")
    }
}
