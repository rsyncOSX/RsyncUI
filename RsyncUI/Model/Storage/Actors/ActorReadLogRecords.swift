//
//  ActorReadLogRecords.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 04/12/2024.
//

import DecodeEncodeGeneric
import Foundation
import OSLog

actor ActorReadLogRecords {
    func readjsonfilelogrecords(_ profile: String?,
                                _ validhiddenIDs: Set<Int>) async -> [LogRecords]? {
        let path = await Homepath()
        var filename = ""
        Logger.process.debugThreadOnly("ActorReadLogRecordsJSON: readjsonfilelogrecords()")
        if let profile, let fullpathmacserial = path.fullpathmacserial {
            filename = fullpathmacserial.appending("/") + profile.appending("/") + SharedConstants().filenamelogrecordsjson
        } else {
            if let fullpathmacserial = path.fullpathmacserial {
                filename = fullpathmacserial.appending("/") + SharedConstants().filenamelogrecordsjson
            }
        }

        Logger.process.debugMessageOnly("ActorReadLogRecordsJSON: readjsonfilelogrecords() from \(filename)")

        let decodeimport = DecodeGeneric()
        do {
            let data = try
                decodeimport.decodeArray(DecodeLogRecords.self, fromFile: filename)

            Logger.process.debugThreadOnly("ActorReadLogRecordsJSON - \(profile ?? "default")")
            return data.compactMap { element in
                let item = LogRecords(element)
                return validhiddenIDs.contains(item.hiddenID) ? item : nil
            }
        } catch {
            let profileName = profile ?? "default profile"
            Logger.process.errorMessageOnly(
                "ActorReadLogRecordsJSON - \(profileName): some ERROR reading logrecords from permanent storage"
            )
        }
        return nil
    }

    deinit {
        Logger.process.debugMessageOnly("ActorReadLogRecords: DEINIT")
    }
}
