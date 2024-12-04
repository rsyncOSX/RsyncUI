//
//  WriteSynchronizeQuicktaskJSON.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 27/04/2021.
//
// swiftlint:disable line_length

import DecodeEncodeGeneric
import Foundation
import OSLog

final class WriteSynchronizeQuicktaskJSON: PropogateError {
    private func writeJSONToPersistentStore(jsonData: Data?) {
        let path = Homepath()
        if let fullpathmacserial = path.fullpathmacserial {
            var configurationfileURL: URL?
            let fullpathmacserialURL = URL(fileURLWithPath: fullpathmacserial)
            configurationfileURL = fullpathmacserialURL.appendingPathComponent("quicktask.json")
            if let jsonData, let configurationfileURL {
                do {
                    try jsonData.write(to: configurationfileURL)
                    Logger.process.info("WriteSynchronizeQuicktaskJSON - write Quicktask to permanent storage")
                } catch let e {
                    let error = e
                    path.propogateerror(error: error)
                }
            }
        }
    }

    private func encodeJSONData(_ configuration: SynchronizeConfiguration) {
        let encodejsondata = EncodeGeneric()
        do {
            if let encodeddata = try encodejsondata.encodedata(data: configuration) {
                writeJSONToPersistentStore(jsonData: encodeddata)
            }
        } catch let e {
            let error = e
            propogateerror(error: error)
        }
    }

    @discardableResult
    init(_ configurations: SynchronizeConfiguration) {
        encodeJSONData(configurations)
    }

    deinit {
        Logger.process.info("WriteSynchronizeQuicktaskJSON deinit")
    }
}

// swiftlint:enable line_length
