//
//  ReadScheduleJSON.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 19/04/2021.
//

//
//  ReadWriteJSON.swift
//  RsyncOSX
//
//  Created by Thomas Evensen on 29/10/2020.
//  Copyright © 2020 Thomas Evensen. All rights reserved.
//

import Combine
import Files
import Foundation

class ReadScheduleJSON: NamesandPaths {
    var schedules: [ConfigurationSchedule]?
    var datafile = [SharedReference.shared.fileschedulesjson]
    var subscriptons = Set<AnyCancellable>()

    init(_ profile: String?, _ validhiddenID: Set<Int>) {
        super.init(profileorsshrootpath: .profileroot)
        self.profile = profile
        datafile.publisher
            .compactMap { filenamejson -> URL? in
                var filename: String = ""
                if let profile = profile {
                    filename = fullroot! + "/" + profile + "/" + filenamejson
                } else {
                    filename = fullroot! + "/" + filenamejson
                }
                return URL(fileURLWithPath: filename)
            }
            .tryMap { url -> Data in
                try Data(contentsOf: url)
            }
            .decode(type: [DecodeSchedule].self, decoder: JSONDecoder())
            .sink { completion in
                print("completion with \(completion)")
            } receiveValue: { [unowned self] data in
                var schedules = [ConfigurationSchedule]()
                for i in 0 ..< data.count {
                    var transformed = TransformSchedulefromJSON().transform(data[i])
                    transformed.profilename = profile
                    if validhiddenID.contains(transformed.hiddenID) {
                        schedules.append(transformed)
                    }
                }
                self.schedules = schedules
                subscriptons.removeAll()
            }.store(in: &subscriptons)
        // Sorting schedule after hiddenID
        schedules?.sort { (schedule1, schedule2) -> Bool in
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

/*
 TODO: fix fullroot!
 */
