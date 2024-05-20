//
//  WriteLogRecordsJSON.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 27/04/2021.
//
// swiftlint: disable non_optional_string_data_conversion

import Combine
import Foundation
import OSLog

class WriteLogRecordsJSON: NamesandPaths {
    var profile: String?
    var subscriptons = Set<AnyCancellable>()
    // Filename for JSON file
    var filename = SharedReference.shared.filenamelogrecordsjson

    private func writeJSONToPersistentStore(_ data: String?) {
        if var atpath = fullpathmacserial {
            do {
                if profile != nil {
                    atpath += "/" + (profile ?? "")
                }
                let folder = try Folder(path: atpath)
                let file = try folder.createFile(named: filename)
                if let data = data {
                    try file.write(data)
                    Logger.process.info("WriteLogRecordsJSON: write logrecords to permanent storage")
                }
            } catch let e {
                let error = e
                propogateerror(error: error)
            }
        }
    }

    // We have to remove UUID and computed properties ahead of writing JSON file
    // done in the .map operator
    @discardableResult
    init(_ profile: String?, _ logrecords: [LogRecords]?) {
        super.init(.configurations)
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
                    self.propogateerror(error: error)
                }
            }, receiveValue: { [unowned self] result in
                let jsonfile = String(data: result, encoding: .utf8)
                writeJSONToPersistentStore(jsonfile)
                subscriptons.removeAll()
            })
            .store(in: &subscriptons)
    }
}

// swiftlint: enable non_optional_string_data_conversion
