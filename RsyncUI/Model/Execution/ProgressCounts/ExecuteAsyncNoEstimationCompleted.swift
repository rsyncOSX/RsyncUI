//
//  ExecuteAsyncNoEstimationCompleted.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 06/01/2024.
//

import Foundation
import Observation

@Observable
final class ExecuteAsyncNoEstimationCompleted {
    var executeasyncnoestimationcompleted: Bool = false
    var estimatedlist: [RemoteDataNumbers]?
    // set uuid if data to be transferred
    var uuids = Set<UUID>()

    func asyncexecutealltasksnoestiamtioncomplete() {
        executeasyncnoestimationcompleted = true
    }

    func startasyncexecutealltasksnoestimation() {
        executeasyncnoestimationcompleted = false
    }

    func appendrecordexecutedlist(_ record: RemoteDataNumbers) {
        if estimatedlist == nil {
            estimatedlist = [RemoteDataNumbers]()
        }
        estimatedlist?.append(record)
    }

    func appenduuid(_ id: UUID) {
        uuids.insert(id)
    }

    func reset() {
        uuids.removeAll()
        estimatedlist = nil
    }
}
