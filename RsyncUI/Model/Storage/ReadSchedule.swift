//
//  ReadSchedule.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 19/04/2021.
//
// swiftlint:disable line_length

import DecodeEncodeGeneric
import Foundation
import OSLog

@MainActor
struct ReadSchedule {
    func readjsonfilecalendar(_ validprofiles: [String]) -> [SchedulesConfigurations]? {
        var filename = ""
        let path = Homepath()

        Logger.process.info("ReadSchedule: readjsonfilecalendar() MAIN THREAD: \(Thread.isMain, privacy: .public) but on \(Thread.current, privacy: .public)")

        if let fullpathmacserial = path.fullpathmacserial {
            filename = fullpathmacserial.appending("/") + SharedConstants().caldenarfilejson
        }

        let decodeimport = DecodeGeneric()
        do {
            if let data = try
                decodeimport.decodearraydatafileURL(DecodeSchedules.self,
                                                    fromwhere: filename)
            {
                // Dont need to sort when reading, the schedules are sorted by runDate when
                // new schedules are added and saved

                Logger.process.info("ReadSchedule - read Calendar from permanent storage \(filename, privacy: .public)")

                return data.compactMap { element in
                    let item = SchedulesConfigurations(element)
                    if item.schedule == ScheduleType.once.rawValue,
                       let daterun = item.dateRun, daterun.en_date_from_string() < Date.now
                    {
                        return nil
                    } else {
                        if let profile = item.profile {
                            return validprofiles.contains(profile) ? item : nil
                        } else {
                            return item
                        }
                    }
                }
            }

        } catch let e {
            Logger.process.info("ReadSchedule: some ERROR reading")
            let error = e
            path.propogateerror(error: error)
        }

        return nil
    }
}

// swiftlint:enable line_length
