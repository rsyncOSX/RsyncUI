//
//  ActorWriteSchedule.swift
// swiftlint:disable line_length

import DecodeEncodeGeneric
import Foundation
import OSLog

actor ActorWriteSchedule {
    private nonisolated func writeJSONToPersistentStore(jsonData: Data?) async {
        let path = await Homepath()

        Logger.process.info("ActorWriteSchedule: writeJSONToPersistentStore() MAIN THREAD \(Thread.isMain)")

        if let fullpathmacserial = path.fullpathmacserial {
            var calendarfileURL: URL?
            let fullpathmacserialURL = URL(fileURLWithPath: fullpathmacserial)
            // "calendar.json"
            // calendarfileURL = await fullpathmacserialURL.appendingPathComponent(SharedReference.shared.caldenarfilejson)
            calendarfileURL = fullpathmacserialURL.appendingPathComponent("calendar.json")
            if let jsonData, let calendarfileURL {
                do {
                    try jsonData.write(to: calendarfileURL)
                    Logger.process.info("ActorWriteSchedule: write Calendar to permanent storage")
                } catch let e {
                    Logger.process.error("ActorWriteSchedule: some ERROR write Calendar to permanent storage")
                    let error = e
                    await path.propogateerror(error: error)
                }
            }
        }
    }

    private nonisolated func encodeJSONData(_ calendar: [SchedulesConfigurations]) async {
        let encodejsondata = await EncodeGeneric()
        do {
            if let encodeddata = try await encodejsondata.encodedata(data: calendar) {
                await writeJSONToPersistentStore(jsonData: encodeddata)
            }
        } catch {
            Logger.process.error("ActorWriteSchedule some ERROR writing")
            return
        }
    }

    @discardableResult
    init(_ calendar: [SchedulesConfigurations]) async {
        await encodeJSONData(calendar)
    }

    deinit {
        Logger.process.info("ActorWriteSchedule deinit")
    }
}

// swiftlint:enable line_length
