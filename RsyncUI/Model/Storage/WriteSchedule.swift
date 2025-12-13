//
//  WriteSchedule.swift

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
                } catch let err {
                    Logger.process.errorMessageOnly("WriteSchedule: some ERROR write Calendar to permanent storage")
                    let error = err
                    path.propagateError(error: error)
                }
            }
        }
    }

    private func encodeJSONData(_ calendar: [SchedulesConfigurations]) {
        let encodejsondata = EncodeGeneric()
        do {
            let encodeddata = try encodejsondata.encode(calendar)
            writeJSONToPersistentStore(jsonData: encodeddata)

        } catch {
            Logger.process.errorMessageOnly("WriteSchedule some ERROR writing")
            return
        }
    }

    @discardableResult
    init(_ calendar: [SchedulesConfigurations]) {
        encodeJSONData(calendar)
    }
}
