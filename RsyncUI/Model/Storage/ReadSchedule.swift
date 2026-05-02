//
//  ActorReadSchedule.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 19/04/2021.
//

import DecodeEncodeGeneric
import Foundation
import OSLog

@MainActor
struct ReadSchedule {
    func readjsonfilecalendar(_ validprofiles: [String]) -> [SchedulesConfigurations]? {
        var filename = ""
        let path = Homepath()
        Logger.process.debugThreadOnly("ActorReadSchedule: readjsonfilecalendar()")
        if let fullpathmacserial = path.fullpathmacserial {
            filename = fullpathmacserial.appending("/") + SharedConstants().caldenarfilejson
        }

        let decodeimport = DecodeGeneric()
        do {
            let data = try
                decodeimport.decodeArray(DecodeSchedules.self,
                                         fromFile: filename)

            return data.compactMap { element in
                let item = SchedulesConfigurations(element)
                if item.schedule == ScheduleType.once.rawValue,
                   let daterun = item.dateRun, daterun.en_date_from_string() < Date.now {
                    return nil
                } else {
                    if let profile = item.profile {
                        return validprofiles.contains(profile) ? item : nil
                    } else {
                        return item
                    }
                }
            }
        } catch {
            let message = "ActorReadSchedule - read Calendar from permanent storage " +
                "\(filename) failed with error: some ERROR reading"
            Logger.process.debugMessageOnly(message)
        }
        return nil
    }
}
