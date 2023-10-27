//
//  ReadScheduleJSON.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 19/04/2021.
//

import Combine
import Foundation
import OSLog

class ReadScheduleJSON: NamesandPaths {
    var schedules: [ConfigurationSchedule]?
    var logrecords: [Log]?
    var filenamedatastore = [SharedReference.shared.fileschedulesjson]
    var subscriptons = Set<AnyCancellable>()

    init(_ profile: String?, _ validhiddenID: Set<Int>) {
        super.init(.configurations)
        // print("ReadScheduleJSON")
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
            .decode(type: [DecodeConfigurationSchedule].self, decoder: JSONDecoder())
            .sink { completion in
                switch completion {
                case .finished:
                    return
                case .failure:
                    Logger.process.info("ReadScheduleJSON: Creating default file for log records")
                    WriteScheduleJSON(nil, nil)
                }
            } receiveValue: { [unowned self] data in
                schedules = [ConfigurationSchedule]()
                for i in 0 ..< data.count {
                    var oneschedule = ConfigurationSchedule(data[i])
                    oneschedule.profilename = profile
                    if validhiddenID.contains(oneschedule.hiddenID) {
                        schedules?.append(oneschedule)
                    }
                }
                if schedules?.count ?? 0 > 0 {
                    logrecords = [Log]()
                    for i in 0 ..< (schedules?.count ?? 0) {
                        if let records = schedules?[i].logrecords {
                            logrecords?.append(contentsOf: records)
                        }
                    }
                    logrecords = logrecords?.sorted(by: \.date, using: >)
                }
                subscriptons.removeAll()
            }.store(in: &subscriptons)
    }
}
