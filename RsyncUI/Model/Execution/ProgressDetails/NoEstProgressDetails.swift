//
//  NoEstProgressDetails.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 06/01/2024.
//

import Foundation
import Observation

@Observable
final class NoEstProgressDetails {
    var executenoestimationcompleted: Bool = false
    var executelist: [RemoteDataNumbers]?
    // UUIDs with data to be transferred
    var uuidswithdatatosynchronize = Set<UUID>()

    func executeAllTasksNoEstimationComplete() {
        executenoestimationcompleted = true
    }

    func startExecuteAllTasksNoEstimation() {
        executenoestimationcompleted = false
    }

    func appendRecordExecutedList(_ record: RemoteDataNumbers) {
        if executelist == nil {
            executelist = [RemoteDataNumbers]()
        }
        executelist?.append(record)
    }

    func appendUUIDWithDataToSynchronize(_ id: UUID) {
        uuidswithdatatosynchronize.insert(id)
    }

    func reset() {
        uuidswithdatatosynchronize.removeAll()
        executelist = nil
    }
}
