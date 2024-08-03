//
//  WriteLogRecordsJSON.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 27/04/2021.
//
// swiftlint:disable line_length

import Combine
import Foundation
import OSLog

@MainActor
final class WriteLogRecordsJSON {
    var profile: String?
    var subscriptons = Set<AnyCancellable>()
    let path = Homepath()

    private func writeJSONToPersistentStore(jsonData: Data?) {
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
                    let myprofile = profile
                    Logger.process.info("WriteLogRecordsJSON - \(myprofile ?? "default profile", privacy: .public): write logrecords to permanent storage")
                } catch let e {
                    let error = e
                    path.propogateerror(error: error)
                }
            }
        }
    }

    // We have to remove UUID and computed properties ahead of writing JSON file
    // done in the .map operator
    @discardableResult
    init(_ profile: String?, _ logrecords: [LogRecords]?) {
        if profile == SharedReference.shared.defaultprofile {
            self.profile = nil
        } else {
            self.profile = profile
        }
        logrecords.publisher
            .map { logrecords -> [DecodeLogRecords] in
                var data = [DecodeLogRecords]()
                for i in 0 ..< logrecords.count {
                    data.append(DecodeLogRecords(logrecords[i]))
                }
                return data
            }
            .encode(encoder: JSONEncoder())
            .sink(receiveCompletion: { completion in
                switch completion {
                case .finished:
                    return
                case let .failure(error):
                    self.path.propogateerror(error: error)
                }
            }, receiveValue: { [unowned self] result in
                writeJSONToPersistentStore(jsonData: result)
                subscriptons.removeAll()
            })
            .store(in: &subscriptons)
    }
}

// swiftlint:enable line_length
