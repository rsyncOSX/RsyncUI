//
//  ReadLogRecordsJSON.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 19/04/2021.
//

import Combine
import Foundation
import OSLog

class ReadLogRecordsJSON: NamesandPaths {
    var logrecords: [LogRecords]?
    var logs: [Log]?
    var filenamedatastore = [SharedReference.shared.filenamelogrecordsjson]
    var subscriptons = Set<AnyCancellable>()

    private func validatepath(_ path: String) throws -> Bool {
        if FileManager.default.fileExists(atPath: path, isDirectory: nil) == false {
            throw Validatedpath.nopath
        }
        return true
    }

    private func failurereadlogrecords(_ profile: String?, _ validhiddenID: Set<Int>) {
        if var atpath = fullpathmacserial {
            do {
                if profile != nil {
                    atpath += "/" + (profile ?? "") + "/" + SharedReference.shared.fileschedulesjson
                } else {
                    atpath += "/" + SharedReference.shared.fileschedulesjson
                }
                let exists = try validatepath(atpath)
                if exists {
                    Logger.process.info("ReadLogRecordsJSON: Copy old file for log records and save to new file")
                    _ = ReadLogrecordsOldName(profile, validhiddenID)
                }
            } catch _ {
                Logger.process.info("ReadLogRecordsJSON: Creating default file for log records")
                var defaultlogrecords = [LogRecords()]
                guard defaultlogrecords.count == 1 else { return }
                defaultlogrecords[0].dateStart = Date().en_us_string_from_date()
                defaultlogrecords[0].profilename = profile
                WriteLogRecordsJSON(profile, defaultlogrecords)
            }
        }
    }

    init(_ profile: String?, _ validhiddenID: Set<Int>) {
        super.init(.configurations)
        filenamedatastore.publisher
            .compactMap { filenamejson -> URL in
                var filename = ""
                if let profile = profile, let path = fullpathmacserial {
                    filename = path + "/" + profile + "/" + filenamejson
                } else {
                    if let path = fullpathmacserial {
                        filename = path + "/" + filenamejson
                    }
                }
                return URL(fileURLWithPath: filename)
            }
            .tryMap { url -> Data in
                try Data(contentsOf: url)
            }
            .decode(type: [DecodeLogRecords].self, decoder: JSONDecoder())
            .sink { completion in
                switch completion {
                case .finished:
                    return
                case .failure:
                    self.failurereadlogrecords(profile, validhiddenID)
                }
            } receiveValue: { [unowned self] data in
                logrecords = [LogRecords]()
                for i in 0 ..< data.count {
                    var oneschedule = LogRecords(data[i])
                    oneschedule.profilename = profile
                    if validhiddenID.contains(oneschedule.hiddenID) {
                        logrecords?.append(oneschedule)
                    }
                }
                if logrecords?.count ?? 0 > 0 {
                    logs = [Log]()
                    for i in 0 ..< (logrecords?.count ?? 0) {
                        if let records = logrecords?[i].logrecords {
                            logs?.append(contentsOf: records)
                        }
                    }
                    logs = logs?.sorted(by: \.date, using: >)
                    Logger.process.info("ReadLogRecordsJSON: read logdata from permanent storage")
                }
                subscriptons.removeAll()
            }.store(in: &subscriptons)
    }
}
