//
//  ActorReadSchedule.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 19/04/2021.
//
// swiftlint:disable line_length

import DecodeEncodeGeneric
import Foundation
import OSLog

actor ActorReadSchedule {
    func readjsonfilecalendar(_ validprofiles: [String]) async -> [SchedulesConfigurations]? {
        let reporterror = ReportError()
        var filename = ""
        let path = await Homepath()
        Logger.process.debugtthreadonly("ActorReadSchedule: readjsonfilecalendar()")
        if let fullpathmacserial = path.fullpathmacserial {
            filename = fullpathmacserial.appending("/") + SharedConstants().caldenarfilejson
        }

        let decodeimport = DecodeGeneric()
        do {
            if let data = try
                decodeimport.decodearraydatafileURL(DecodeSchedules.self,
                                                    fromwhere: filename)
            {
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
            Logger.process.debugmesseageonly("ActorReadSchedule - read Calendar from permanent storage \(filename) failed with error: some ERROR reading")
            let error = e
            await reporterror.propogateerror(error: error)
        }

        return nil
    }
}

// swiftlint:enable line_length
