//
//  ActorReadLogRecordsJSON.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 04/12/2024.
//

import DecodeEncodeGeneric
import Foundation
import OSLog

actor ActorReadLogRecordsJSON {

    func readjsonfilelogrecords(_ profile: String?, _ validhiddenIDs: Set<Int>) async -> [LogRecords]? {
        let path = await Homepath()
        var filename = ""
        
        Logger.process.info("readjsonfilelogrecords(): on main thread: \(Thread.isMain)")
        
        if let profile, profile != "Default profile", let path = path.fullpathmacserial {
            filename = path + "/" + profile + "/" + "logrecords.json"
        } else {
            if let path = path.fullpathmacserial {
                filename = path + "/" + "logrecords.json"
            }
        }
        let decodeimport = await DecodeGeneric()
        do {
            if let data = try
                await decodeimport.decodearraydatafileURL(DecodeLogRecords.self, fromwhere: filename)
            {
                Logger.process.info("ReadLogRecordsJSON - \(profile ?? "default profile", privacy: .public): read logrecords from permanent storage")
                return data.compactMap { element in
                    let item = LogRecords(element)
                    return validhiddenIDs.contains(item.hiddenID) ? item : nil
                }
            }

        } catch  {
            Logger.process.info("ReadLogRecordsJSON - \(profile ?? "default profile", privacy: .public): some ERROR reading logrecords from permanent storage")
            return nil
        }
        return nil
    }

    deinit {
        Logger.process.info("ReadLogRecordsJSON: deinit")
    }
}
