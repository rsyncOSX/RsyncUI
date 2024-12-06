//
//  ActorReadSynchronizeQuicktaskJSON.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 19/04/2021.
//
// swiftlint:disable line_length

import DecodeEncodeGeneric
import Foundation
import OSLog

actor ActorReadSynchronizeQuicktaskJSON {
    func readjsonfilequicktask() async -> SynchronizeConfiguration? {
        var filename = ""
        let path = await Homepath()

        Logger.process.info("readjsonfilequicktask(): on main thread: \(Thread.isMain)")

        if let path = path.fullpathmacserial {
            filename = path + "/" + "quicktask.json"
        }

        let decodeimport = await DecodeGeneric()
        do {
            if let data = try
                await decodeimport.decodestringdatafileURL(DecodeSynchronizeConfiguration.self,
                                                           fromwhere: filename)
            {
                Logger.process.info("ReadSynchronizeQuicktaskJSON - read Quicktask from permanent storage")
                return SynchronizeConfiguration(data)
            }

        } catch let e {
            Logger.process.info("ReadSynchronizeQuicktaskJSON: some ERROR reading")
            let error = e
            await path.propogateerror(error: error)
        }

        return nil
    }

    deinit {
        Logger.process.info("ReadSynchronizeQuicktaskJSON: deinit")
    }
}

// swiftlint:enable line_length
