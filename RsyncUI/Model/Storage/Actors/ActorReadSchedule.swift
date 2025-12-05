//
//  ActorReadSchedule.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 19/04/2021.
//

import DecodeEncodeGeneric
import Foundation
import OSLog

actor ActorReadSchedule {
    func readjsonfilecalendar(_ validprofiles: [String]) async -> [SchedulesConfigurations]? {
        var filename = ""
        let path = await Homepath()
        Logger.process.debugtthreadonly("ActorReadSchedule: readjsonfilecalendar()")
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
            Logger.process.debugmessageonly("ActorReadSchedule - read Calendar from permanent storage \(filename) failed with error: some ERROR reading")
        }

        /*
          I do not wish to receive that annoying message.
         } catch let e {
             Logger.process.debugmessageonly("ActorReadSchedule - read Calendar from permanent storage \(filename) failed with error: some ERROR reading")
             let error = e
             await reporterror.propagateError(error: error)
         }
          */
        return nil
    }
}
