//
//  LogStatsChartView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 29/08/2025.
//

import Charts
import SwiftUI

// MARK: - SwiftUI Chart View

struct LogStatsChartView: View {
    @Bindable var rsyncUIdata: RsyncUIconfigurations
    @Binding var selecteduuids: Set<SynchronizeConfiguration.ID>

    @State private var logEntries: [LogEntry]?

    var body: some View {
        VStack {
            Text("Rsync Log Statistics")
                .font(.title)
                .padding(.bottom, 10)

            Chart {
                ForEach(logEntries ?? []) { entry in
                    LineMark(
                        x: .value("Date", entry.date),
                        y: .value("Number of Files", entry.files)
                    )
                    .foregroundStyle(.blue)
                    .symbol(by: .value("Type", "Files"))

                    LineMark(
                        x: .value("Date", entry.date),
                        y: .value("Data Transferred (MB)", entry.transferredMB)
                    )
                    .foregroundStyle(.green)
                    .symbol(by: .value("Type", "Data"))
                }
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .day))
            }
            .frame(height: 300)
        }
        .padding()
        .onAppear {
            Task {
                let actorreadlogs = ActorLogCharts()
                let logrecords = await actorreadlogs.readjsonfilelogrecords(rsyncUIdata.profile, validhiddenIDs)
                let logs = await actorreadlogs.updatelogsbyhiddenID(logrecords, hiddenID) ?? []
                logEntries = await actorreadlogs.parseLogData(from: logs)
            }
        }
    }

    var validhiddenIDs: Set<Int> {
        var temp = Set<Int>()
        if let configurations = rsyncUIdata.configurations {
            _ = configurations.map { record in
                temp.insert(record.hiddenID)
            }
        }
        return temp
    }

    var hiddenID: Int {
        if let configurations = rsyncUIdata.configurations {
            if let index = configurations.firstIndex(where: { $0.id == selecteduuids.first }) {
                return configurations[index].hiddenID
            } else {
                return 0
            }
        }
        return -1
    }
}
