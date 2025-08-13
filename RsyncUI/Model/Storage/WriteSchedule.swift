//
//  WriteSchedule.swift
// swiftlint:disable line_length

import DecodeEncodeGeneric
import Foundation
import OSLog

@MainActor
struct  WriteSchedule {
    private func writeJSONToPersistentStore(jsonData: Data?) async {
        let path = Homepath()

        Logger.process.info("WriteSchedule: writeJSONToPersistentStore() MAIN THREAD: \(Thread.isMain) but on \(Thread.current)")

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

    private func encodeJSONData(_ calendar: [SchedulesConfigurations]) async {
        let encodejsondata = EncodeGeneric()
        do {
            Logger.process.info("WriteSchedule: encodeJSONData() MAIN THREAD: \(Thread.isMain) but on \(Thread.current)")
            if let encodeddata = try encodejsondata.encodedata(data: calendar) {
                await writeJSONToPersistentStore(jsonData: encodeddata)
            }
        } catch {
            Logger.process.error("WriteSchedule some ERROR writing")
            return
        }
    }

    @discardableResult
    init(_ calendar: [SchedulesConfigurations]) async {
        await encodeJSONData(calendar)
    }
}

// swiftlint:enable line_length
