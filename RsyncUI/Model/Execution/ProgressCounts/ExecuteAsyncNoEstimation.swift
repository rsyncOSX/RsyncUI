//
//  ExecuteAsyncNoEstimation.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 06/01/2024.
//

import Foundation
import Observation

@Observable
final class ExecuteAsyncNoEstimation {
    var executeasyncnoestimationcompleted: Bool = false
    var executelist: [RemoteDataNumbers]?
    // set uuid if data to be transferred
    var uuids = Set<UUID>()

    func asyncexecutealltasksnoestiamtioncomplete() {
        executeasyncnoestimationcompleted = true
    }

    func startasyncexecutealltasksnoestimation() {
        executeasyncnoestimationcompleted = false
    }

    func appendrecordexecutedlist(_ record: RemoteDataNumbers) {
        if executelist == nil {
            executelist = [RemoteDataNumbers]()
        }
        executelist?.append(record)
    }

    func appenduuid(_ id: UUID) {
        uuids.insert(id)
    }

    func reset() {
        uuids.removeAll()
        executelist = nil
    }
}
