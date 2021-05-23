//
//  ReadSchedulesPLIST.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 21/05/2021.
//
// swiftlint:disable cyclomatic_complexity
//
// This class is used only when converting PLIST file to JSON

import Combine
import Foundation

final class ReadSchedulesPLIST: NamesandPaths {
    var filenamedatastore = ["scheduleRsync.plist"]
    var subscriptons = Set<AnyCancellable>()
    var schedules = [ConfigurationSchedule]()
    // True if PLIST data is found
    var thereisplistdata: Bool = false

    // JSON data already exists
    var jsonfileexist: Bool {
        var filename: String = ""
        if let profile = profile, let path = fullpathmacserial {
            filename = path + "/" + profile + "/" + SharedReference.shared.fileschedulesjson
        } else {
            if let fullroot = fullpathmacserial {
                filename = fullroot + "/" + SharedReference.shared.fileconfigurationsjson
            }
        }
        let fileManager = FileManager.default
        return fileManager.fileExists(atPath: filename)
    }

    // Write data as JSON file
    func writedatatojson() {
        _ = WriteScheduleJSON(profile, schedules)
    }

    private func setschedules(_ data: [NSDictionary]) {
        var scheduleplist: ConfigurationSchedulePLIST?
        for i in 0 ..< data.count {
            let dict = data[i]
            if let log = dict.value(forKey: DictionaryStrings.executed.rawValue) {
                scheduleplist = ConfigurationSchedulePLIST(dictionary: dict, log: log as? NSArray)
            } else {
                scheduleplist = ConfigurationSchedulePLIST(dictionary: dict, log: nil)
            }
            if let scheduleplist = scheduleplist {
                var schedule = ConfigurationSchedule()
                schedule.hiddenID = scheduleplist.hiddenID
                schedule.offsiteserver = scheduleplist.offsiteserver
                schedule.dateStart = scheduleplist.dateStart
                schedule.dateStop = scheduleplist.dateStop
                schedule.schedule = scheduleplist.schedule
                schedule.logrecords = scheduleplist.logrecords
                schedule.profilename = scheduleplist.profilename
                schedules.append(schedule)
            }
        }
        // Sorting schedule after hiddenID
        schedules.sort { schedule1, schedule2 -> Bool in
            if schedule1.hiddenID > schedule2.hiddenID {
                return false
            } else {
                return true
            }
        }

        if schedules.count > 0 { thereisplistdata = true }
    }

    override init(_ profile: String?) {
        super.init(.configurations)
        self.profile = profile
        filenamedatastore.publisher
            .compactMap { name -> URL? in
                var filename: String = ""
                if let profile = profile, let path = fullpathmacserial {
                    filename = path + "/" + profile + "/" + name
                } else {
                    if let fullroot = fullpathmacserial {
                        filename = fullroot + "/" + name
                    }
                }
                return URL(fileURLWithPath: filename)
            }
            .tryMap { url -> NSDictionary in
                try NSDictionary(contentsOf: url, error: ())
            }
            .sink(receiveCompletion: { completion in
                switch completion {
                case .finished:
                    return
                case let .failure(error):
                    self.propogateerror(error: error)
                }
            }, receiveValue: { [unowned self] data in
                if let items = data.object(forKey: "Schedule") as? NSArray {
                    let schedules = items.map { row -> NSDictionary? in
                        switch row {
                        case is NSNull:
                            return nil
                        case let value as NSDictionary:
                            return value
                        default:
                            return nil
                        }
                    }
                    guard schedules.count > 0 else { return }
                    var data = [NSDictionary]()
                    for i in 0 ..< schedules.count {
                        if let item = schedules[i] {
                            data.append(item)
                        }
                    }
                    setschedules(data)
                }
                subscriptons.removeAll()
            }).store(in: &subscriptons)
    }
}
