//
//  WriteSchedule.swift

import Foundation
import OSLog

@MainActor
enum WriteSchedule {
    static func write(_ calendar: [SchedulesConfigurations]) async {
        let path = Homepath()

        guard let fullpathmacserial = path.fullpathmacserial else { return }

        let fullpathmacserialURL = URL(fileURLWithPath: fullpathmacserial)
        let calendarfileURL = fullpathmacserialURL.appendingPathComponent(SharedConstants().caldenarfilejson)

        do {
            try await SharedJSONStorageWriter.shared.write(calendar, to: calendarfileURL)
        } catch {
            Logger.process.errorMessageOnly("WriteSchedule: some ERROR write Calendar to permanent storage")
            path.propagateError(error: error)
        }
    }
}
