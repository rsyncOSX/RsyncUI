//
//  LogStatsChartView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 29/08/2025.
//

import Charts
import OSLog
import SwiftUI

enum DataInChart: String, CaseIterable, Identifiable, CustomStringConvertible {
    case files
    case seconds
    case numbers

    var id: String { rawValue }
    var description: String { rawValue.localizedLowercase }
}

enum TypeofChart: String, CaseIterable, Identifiable, CustomStringConvertible {
    case linemarkchart
    case barchart

    var id: String { rawValue }
    var description: String { rawValue.localizedLowercase }
}

enum FilesOrMB: String, CaseIterable, Identifiable, CustomStringConvertible {
    case files
    case sizeinmb

    var id: String { rawValue }
    var description: String { rawValue.localizedLowercase }
}


struct LogStatsChartView: View {
    @Bindable var rsyncUIdata: RsyncUIconfigurations
    @Binding var selecteduuids: Set<SynchronizeConfiguration.ID>

    @State private var logentries: [LogEntry]?
    @State private var selectedatainchart: DataInChart = .files
    @State private var typeofchart: TypeofChart = .linemarkchart
    @State private var filesormb: FilesOrMB = .files

    var body: some View {
        VStack {
            HStack {
                Text("Log Statistics: rows \(logentries?.count ?? 0)")
                    .font(.title)
                    .padding(.bottom, 10)
                
                Picker(NSLocalizedString("Data", comment: ""),
                       selection: $selectedatainchart)
                {
                    ForEach(DataInChart.allCases) { Text($0.description)
                            .tag($0)
                    }
                }
                .pickerStyle(DefaultPickerStyle())
                .frame(width: 180)
                
                Picker(NSLocalizedString("Type", comment: ""),
                       selection: $typeofchart)
                {
                    ForEach(TypeofChart.allCases) { Text($0.description)
                            .tag($0)
                    }
                }
                .pickerStyle(DefaultPickerStyle())
                .frame(width: 180)
                
                Picker(NSLocalizedString("Files or MB", comment: ""),
                       selection: $filesormb)
                {
                    ForEach(FilesOrMB.allCases) { Text($0.description)
                            .tag($0)
                    }
                }
                .pickerStyle(DefaultPickerStyle())
                .frame(width: 180)
            }
            
            if typeofchart == .linemarkchart {
                Chart {
                    ForEach(logentries ?? []) { entry in
                        switch selectedatainchart {
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
            } else {
                Chart {
                    ForEach(logentries ?? []) { entry in
                        
                        switch selectedatainchart {
                        case .files:
                            BarMark(
                                x: .value("Date", entry.date),
                                y: .value("Number of Files", entry.files)
                            )
                            .foregroundStyle(.blue)
                            .symbol(by: .value("Type", "Files"))
                        case .seconds:
                            BarMark(
                                x: .value("Date", entry.date),
                                y: .value("Seconds", entry.seconds)
                            )
                            .foregroundStyle(.red)
                            .symbol(by: .value("Type", "Seconds"))
                        case .numbers:
                            BarMark(
                                x: .value("Date", entry.date),
                                y: .value("Data Transferred (MB)", entry.transferredMB)
                            )
                            .foregroundStyle(.green)
                            .symbol(by: .value("Type", "Data"))
                        }
                    }
                }
                
            }
            
            
        }
        .padding()
        .onAppear {
            Task {
                let actorreadlogs = ActorReadLogRecordsJSON()
                let actorreadchartsdata = ActorLogChartsData()
                let logrecords = await actorreadlogs.readjsonfilelogrecords(rsyncUIdata.profile, validhiddenIDs)
                let alllogs = await actorreadlogs.updatelogsbyhiddenID(logrecords, hiddenID) ?? []
                let parsedlogs = await actorreadchartsdata.parselogrecords(from: alllogs)
                logentries = await actorreadchartsdata.selectMaxValueFilesDates(from: parsedlogs)
            }
        }
        .onChange(of: filesormb) {
            Task {
                let actorreadlogs = ActorReadLogRecordsJSON()
                let actorreadchartsdata = ActorLogChartsData()
                let logrecords = await actorreadlogs.readjsonfilelogrecords(rsyncUIdata.profile, validhiddenIDs)
                let alllogs = await actorreadlogs.updatelogsbyhiddenID(logrecords, hiddenID) ?? []
                let parsedlogs = await actorreadchartsdata.parselogrecords(from: alllogs)
                if filesormb == .files {
                    logentries = await actorreadchartsdata.selectMaxValueFilesDates(from: parsedlogs)
                } else {
                    logentries = await actorreadchartsdata.selectMaxValueMBDates(from: parsedlogs)
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
}
