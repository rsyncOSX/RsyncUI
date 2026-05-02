//
//  ObservableChartData.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 04/09/2025.
//

import Foundation
import Observation
import OSLog

@Observable
final class ObservableChartData {
    var parsedlogs: [LogEntry]?

    /// Only read logrecords from store once
    func readandparselogs(
        profile: String?,
        configurations: [SynchronizeConfiguration]?,
        hiddenID: Int
    ) async {
        guard parsedlogs == nil else { return }
        let actorreadlogs = ActorReadLogRecords()
        let logrecords = await LogStoreService.loadStore(
            profile: profile,
            configurations: configurations
        )
        let alllogs = await actorreadlogs.updatelogsbyhiddenID(logrecords, hiddenID) ?? []
        parsedlogs = await actorreadlogs.parselogrecords(from: alllogs)
    }

    deinit {
        Logger.process.debugMessageOnly("ObservableChartData: DEINIT")
    }
}
