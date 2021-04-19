//
//  WriteScheduleJSON.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 19/04/2021.
//

import Combine
import Files
import Foundation

class WriteScheduleJSONNEW: NamesandPaths {
    var schedules: [ConfigurationSchedule]?
    var datafile = [SharedReference.shared.fileschedulesjson]
    var subscriptons = Set<AnyCancellable>()

    init(_ profile: String?, _ schedules: [ConfigurationSchedule]?) {
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
                let schedules = [ConfigurationSchedule]()
                for i in 0 ..< data.count {
                    var transformed = TransformSchedulefromJSON().transform(data[i])
                    transformed.profilename = profile
                }
                self.schedules = schedules
                subscriptons.removeAll()
            }.store(in: &subscriptons)
    }
}

/*
 TODO: fix fullroot!
 */

