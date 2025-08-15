//
//  WriteSchedule.swift
// swiftlint:disable line_length

import DecodeEncodeGeneric
import Foundation
import OSLog

@MainActor
struct WriteSchedule {
    private func writeJSONToPersistentStore(jsonData: Data?) {
        let path = Homepath()

        if let fullpathmacserial = path.fullpathmacserial {
            var calendarfileURL: URL?
            let fullpathmacserialURL = URL(fileURLWithPath: fullpathmacserial)
            calendarfileURL = fullpathmacserialURL.appendingPathComponent(SharedConstants().caldenarfilejson)
            if let jsonData, let calendarfileURL {
                do {
                    try jsonData.write(to: calendarfileURL)
                    Logger.process.info("WriteSchedule: write Calendar to permanent storage")
                } catch let e {
                    Logger.process.error("WriteSchedule: some ERROR write Calendar to permanent storage")
                    let error = e
                    path.propogateerror(error: error)
                }
            }
        }
    }

    private func encodeJSONData(_ calendar: [SchedulesConfigurations]) {
        let encodejsondata = EncodeGeneric()
        do {
            if let encodeddata = try encodejsondata.encodedata(data: calendar) {
                writeJSONToPersistentStore(jsonData: encodeddata)
            }
        } catch {
            Logger.process.error("WriteSchedule some ERROR writing")
            return
        }
    }

    @discardableResult
    init(_ calendar: [SchedulesConfigurations]) {
        encodeJSONData(calendar)
    }
}

// swiftlint:enable line_length
