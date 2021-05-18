//
//  ReadScheduleJSON.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 19/04/2021.
//

import Combine
import Files
import Foundation

class ReadScheduleJSON: NamesandPaths {
    var schedules: [ConfigurationSchedule]?
    var filenamedatastore = [SharedReference.shared.fileschedulesjson]
    var subscriptons = Set<AnyCancellable>()

    init(_ profile: String?, _ validhiddenID: Set<Int>) {
        super.init(.configurations)
        self.profile = profile
        filenamedatastore.publisher
            .compactMap { filenamejson -> URL? in
                var filename: String = ""
                if let profile = profile, let fullroot = fullpathmacserial {
                    filename = fullroot + "/" + profile + "/" + filenamejson
                } else {
                    if let fullroot = fullpathmacserial {
                        filename = fullroot + "/" + filenamejson
                    }
                }
                return URL(fileURLWithPath: filename)
            }
            .tryMap { url -> Data in
                try Data(contentsOf: url)
            }
            .decode(type: [DecodeSchedule].self, decoder: JSONDecoder())
            .sink { completion in
                switch completion {
                case .finished:
                    // print("The publisher finished normally.")
                    return
                case let .failure(error):
                    self.propogateerror(error: error)
                }
            } receiveValue: { [unowned self] data in
                var schedules = [ConfigurationSchedule]()
                for i in 0 ..< data.count {
                    var transformed = TransformSchedulefromJSON().transform(data[i])
                    transformed.profilename = profile
                    // Validate that the hidden ID is OK,
                    // schedule != Scheduletype.stopped.rawValue, logs count > 0
                    if validhiddenID.contains(transformed.hiddenID),
                       transformed.schedule != Scheduletype.stopped.rawValue,
                       (transformed.logrecords?.count ?? 0) > 0
                    {
                        schedules.append(transformed)
                    }
                }
                self.schedules = schedules
                subscriptons.removeAll()
            }.store(in: &subscriptons)
        // Sorting schedule after hiddenID
        schedules?.sort { schedule1, schedule2 -> Bool in
            if schedule1.hiddenID > schedule2.hiddenID {
                return false
            } else {
                return true
            }
        }
        if SharedReference.shared.checkinput {
            schedules = Reorgschedule().mergerecords(data: schedules)
        }
    }
}
