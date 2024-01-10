//
//  ReadLogrecordsOldAndSaveNewfile.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 10/01/2024.
//

import Combine
import Foundation
import OSLog

class ReadLogrecordsOldAndSaveNewfile: NamesandPaths {
    var logrecords: [LogRecords]?
    var filenamedatastore = [SharedReference.shared.fileschedulesjson]
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
                // Write old logrecords to new file for logrecords
                WriteLogRecordsJSON(profile, logrecords)
                subscriptons.removeAll()
            }.store(in: &subscriptons)
    }
}
