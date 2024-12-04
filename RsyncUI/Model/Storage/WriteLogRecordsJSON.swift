//
//  WriteLogRecordsJSON.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 27/04/2021.
//
// swiftlint:disable line_length

import DecodeEncodeGeneric
import Foundation
import OSLog

final class WriteLogRecordsJSON: PropogateError {
    private func writeJSONToPersistentStore(jsonData: Data?, _ profile: String?) {
        let path = Homepath()
        var profile: String?
        if profile == SharedReference.shared.defaultprofile {
            profile = nil
        }
        if let fullpathmacserial = path.fullpathmacserial {
            var logrecordfileURL: URL?
            let fullpathmacserialURL = URL(fileURLWithPath: fullpathmacserial)
            if let profile {
                let tempURL = fullpathmacserialURL.appendingPathComponent(profile)
                logrecordfileURL = tempURL.appendingPathComponent(SharedReference.shared.filenamelogrecordsjson)
            } else {
                logrecordfileURL = fullpathmacserialURL.appendingPathComponent(SharedReference.shared.filenamelogrecordsjson)
            }
            if let jsonData, let logrecordfileURL {
                do {
                    try jsonData.write(to: logrecordfileURL)
                    let myprofile = profile ?? "Default profile"
                    Logger.process.info("WriteLogRecordsJSON - \(myprofile), privacy: .public): write logrecords to permanent storage")
                } catch let e {
                    let error = e
                    path.propogateerror(error: error)
                }
            }
        }
    }

    private func encodeJSONData(_ logrecords: [LogRecords], _ profile: String?) {
        let encodejsondata = EncodeGeneric()
        do {
            if let encodeddata = try encodejsondata.encodedata(data: logrecords) {
                writeJSONToPersistentStore(jsonData: encodeddata, profile)
            }
        } catch let e {
            let error = e
            propogateerror(error: error)
        }
    }

    @discardableResult
    init(_ profile: String?, _ logrecords: [LogRecords]?) {
        if let logrecords {
            encodeJSONData(logrecords, profile)
        }
    }

    deinit {
        Logger.process.info("WriteLogRecordsJSON deinit")
    }
}

// swiftlint:enable line_length
