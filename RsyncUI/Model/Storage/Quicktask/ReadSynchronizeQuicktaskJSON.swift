//
//  ReadSynchronizeQuicktaskJSON.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 19/04/2021.
//
// swiftlint:disable line_length

import DecodeEncodeGeneric
import Foundation
import OSLog

@MainActor
final class ReadSynchronizeQuicktaskJSON: PropogateError {
    var configuration: SynchronizeConfiguration?
    let path = Homepath()

    private func importjsonfile(_ filenamedatastore: String) {
        let decodeimport = DecodeGeneric()
        do {
            if let data = try
                decodeimport.decodestringdatafileURL(DecodeSynchronizeConfiguration.self,
                                                     fromwhere: filenamedatastore)
            {
                configuration = SynchronizeConfiguration(data)
                Logger.process.info("ReadSynchronizeQuicktaskJSON - read Quicktask from permanent storage")
            }

        } catch let e {
            let error = e
            propogateerror(error: error)
        }
    }

    init() {
        if let path = path.fullpathmacserial {
            let filename = path + "/" + "quicktask.json"
            importjsonfile(filename)
        }
    }

    deinit {
        Logger.process.info("ReadSynchronizeQuicktaskJSON: deinit")
    }
}

// swiftlint:enable line_length
