//
//  ExecuteNoEstimationProgressDetails.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 06/01/2024.
//

import Foundation
import Observation

@Observable
final class ExecuteNoEstimationProgressDetails {
    var executenoestimationcompleted: Bool = false
    var executelist: [RemoteDataNumbers]?
    // UUIDs with data to be transferred
    var uuidswithdatatosynchronize = Set<UUID>()

    func executealltasksnoestiamtioncomplete() {
        executenoestimationcompleted = true
    }

    func startexecutealltasksnoestimation() {
        executenoestimationcompleted = false
    }

    func appendrecordexecutedlist(_ record: RemoteDataNumbers) {
        if executelist == nil {
            executelist = [RemoteDataNumbers]()
        }
        executelist?.append(record)
    }

    func appenduuidwithdatatosynchronize(_ id: UUID) {
        uuidswithdatatosynchronize.insert(id)
    }

    func reset() {
        uuidswithdatatosynchronize.removeAll()
        executelist = nil
    }
}
