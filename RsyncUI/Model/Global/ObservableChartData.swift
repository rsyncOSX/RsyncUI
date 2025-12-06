//
//  ObservableChartData.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 04/09/2025.
//

import Foundation
import Observation
import OSLog

@Observable @MainActor
final class ObservableChartData {
    var parsedlogs: [LogEntry]?

    // Only read logrecords from store once
    func readandparselogs(profile: String?, validhiddenIDs: Set<Int>, hiddenID: Int) async {
        guard parsedlogs == nil else { return }
        // Read logrecords
        let actorreadlogs = ActorReadLogRecordsJSON()
        let logrecords = await actorreadlogs.readjsonfilelogrecords(profile, validhiddenIDs)
        let actorreadchartsdata = ActorLogChartsData()
        let alllogs = await actorreadlogs.updatelogsbyhiddenID(logrecords, hiddenID) ?? []
        // LogEntry logs
        parsedlogs = await actorreadchartsdata.parselogrecords(from: alllogs)
    }

    deinit {
        Logger.process.debugMessageOnly("ObservableChartData: DEINIT")
    }
}
