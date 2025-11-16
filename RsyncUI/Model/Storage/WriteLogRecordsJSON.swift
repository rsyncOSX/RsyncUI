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

@MainActor
final class WriteLogRecordsJSON {
    let path = Homepath()

    private func writeJSONToPersistentStore(jsonData: Data?, _ profile: String?) {
        if let fullpathmacserial = path.fullpathmacserial {
            var logrecordfileURL: URL?
            let fullpathmacserialURL = URL(fileURLWithPath: fullpathmacserial)
            if let profile {
                let tempURL = fullpathmacserialURL.appendingPathComponent(profile)
                logrecordfileURL = tempURL.appendingPathComponent(SharedConstants().filenamelogrecordsjson)
            } else {
                logrecordfileURL = fullpathmacserialURL.appendingPathComponent(SharedConstants().filenamelogrecordsjson)
            }
            if let jsonData, let logrecordfileURL {
                do {
                    try jsonData.write(to: logrecordfileURL)
                } catch let e {
                    Logger.process.error("WriteLogRecordsJSON - \(profile ?? "default profile", privacy: .public): some ERROR writing logrecords to permanent storage")
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
            path.propogateerror(error: error)
        }
    }

    @discardableResult
    init(_ profile: String?, _ logrecords: [LogRecords]?) {
        if let logrecords {
            encodeJSONData(logrecords, profile)
        }
    }

    deinit {
        Logger.process.debugmesseageonly("WriteLogRecordsJSON DEINIT")
    }
}

// swiftlint:enable line_length
