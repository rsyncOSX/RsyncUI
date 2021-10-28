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
        // print("ReadScheduleJSON")
        filenamedatastore.publisher
            .compactMap { filenamejson -> URL in
                var filename: String = ""
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
                    // print("The publisher finished normally.")
                    return
                case let .failure(error):
                    self.propogateerror(error: error)
                }
            } receiveValue: { [unowned self] data in
                var schedules = [ConfigurationSchedule]()
                for i in 0 ..< data.count {
                    var schedule = ConfigurationSchedule(data[i])
                    schedule.profilename = profile
                    // Validate that the hidden ID is OK,
                    // schedule != Scheduletype.stopped.rawValue, logs count > 0
                    if validhiddenID.contains(schedule.hiddenID),
                       schedule.schedule != Scheduletype.stopped.rawValue
                    {
                        schedules.append(schedule)
                    }
                }
                self.schedules = schedules
                subscriptons.removeAll()
            }.store(in: &subscriptons)
        // Sorting schedule after hiddenID
        /* Dont need to sort
         schedules?.sort { schedule1, schedule2 -> Bool in
             if schedule1.hiddenID > schedule2.hiddenID {
                 return false
             } else {
                 return true
             }
         }
         */
        if SharedReference.shared.checkinput {
            schedules = Reorgschedule().mergerecords(data: schedules)
        }
    }
}
