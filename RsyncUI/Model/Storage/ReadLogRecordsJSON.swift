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
                    Logger.process.warning("ReadLogRecordsJSON: something is wrong, could not read logdata from permanent storage")
                    return
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
                    Logger.process.info("ReadLogRecordsJSON: read logrecords from permanent storage")
                } else {
                    Logger.process.warning("ReadLogRecordsJSON: NO logrecords in JSON from permanent storage")
                }
                subscriptons.removeAll()
            }.store(in: &subscriptons)
    }
}
