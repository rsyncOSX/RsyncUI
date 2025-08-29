//
//  LogStatsChartView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 29/08/2025.
//

import Charts
import SwiftUI

enum TypeofChart: String, CaseIterable, Identifiable, CustomStringConvertible {
    case files
    case seconds
    case numbers

    var id: String { rawValue }
    var description: String { rawValue.localizedLowercase }
}

struct LogStatsChartView: View {
    @Bindable var rsyncUIdata: RsyncUIconfigurations
    @Binding var selecteduuids: Set<SynchronizeConfiguration.ID>

    @State private var logentries: [LogEntry]?
    @State private var selectedtypechart: TypeofChart = .files

    var body: some View {
        VStack {
            
            HStack {
                
                Text("Rsync Log Statistics")
                    .font(.title)
                    .padding(.bottom, 10)
                
                Picker(NSLocalizedString("Chart", comment: ""),
                       selection: $selectedtypechart)
                {
                    ForEach(TypeofChart.allCases) { Text($0.description)
                        .tag($0)
                    }
                }
                .pickerStyle(DefaultPickerStyle())
                .frame(width: 180)
            }
            
            Chart {
                ForEach(logentries ?? []) { entry in
                    
                    switch selectedtypechart {
                    case .files:
                        LineMark(
                            x: .value("Date", entry.date),
                            y: .value("Number of Files", entry.files)
                        )
                        .foregroundStyle(.blue)
                        .symbol(by: .value("Type", "Files"))
                    case .seconds:
                        LineMark(
                            x: .value("Date", entry.date),
                            y: .value("Seconds", entry.seconds)
                        )
                        .foregroundStyle(.red)
                        .symbol(by: .value("Type", "Seconds"))
                    case .numbers:
                        LineMark(
                            x: .value("Date", entry.date),
                            y: .value("Data Transferred (MB)", entry.transferredMB)
                        )
                        .foregroundStyle(.green)
                        .symbol(by: .value("Type", "Data"))
                    }
                }
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .day))
            }
            .chartLegend(.automatic)
        }
        .padding()
        .onAppear {
            Task {
                let actorreadlogs = ActorReadLogRecordsJSON()
                let actorreadchartsdata = ActorLogChartsData()
                let logrecords = await actorreadlogs.readjsonfilelogrecords(rsyncUIdata.profile, validhiddenIDs)
                let logs = await actorreadlogs.updatelogsbyhiddenID(logrecords, hiddenID) ?? []
                let logs2 = await actorreadchartsdata.parselogrecords(from: logs)
                logentries = await actorreadchartsdata.selectlargestbydate(from: logs2)
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
