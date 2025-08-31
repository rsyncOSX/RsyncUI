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
    @State private var typeofchartbool: Bool = true // True Barchart
    @State private var typeofchart: TypeofChart = .barchart
    @State private var filesormbbool: Bool = true // True files
    @State private var filesormb: FilesOrMB = .files
    @State private var numberofdata: String = ""

    var body: some View {
        VStack {
            HStack {
                Text("Statistics: rows \(logentries?.count ?? 0)")
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
                
                Toggle("Line or Bar", isOn: $typeofchartbool)
                    .toggleStyle(.switch)
                    .onChange(of: typeofchartbool) {
                        if typeofchartbool {
                            typeofchart = .barchart
                        } else {
                            typeofchart = .linemarkchart
                        }
                    }
                
                Toggle("MB or Files", isOn: $filesormbbool)
                    .toggleStyle(.switch)
                    .onChange(of: filesormbbool) {
                        if filesormbbool {
                            filesormb  = .files
                        } else {
                            filesormb  = .sizeinmb
                        }
                    }
                
                EditValueErrorScheme(50, "Num", $numberofdata, setnumber(numberofdata))
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
                    if numberofdata.isEmpty {
                        logentries = await actorreadchartsdata.selectMaxValueFilesDates(from: parsedlogs)
                    } else {
                        let allmaxlogentries = await actorreadchartsdata.selectMaxValueFilesDates(from: parsedlogs)
                        logentries = await actorreadchartsdata.getTopNMaxPerDaybyfiles(from: allmaxlogentries, count: Int(numberofdata) ?? 10)
                    }
                    
                } else {
                    if numberofdata.isEmpty {
                        logentries = await actorreadchartsdata.selectMaxValueMBDates(from: parsedlogs)
                    } else {
                        let allmaxlogentries = await actorreadchartsdata.selectMaxValueMBDates(from: parsedlogs)
                        logentries = await actorreadchartsdata.getTopNMaxPerDaybyMB(from: allmaxlogentries, count: Int(numberofdata) ?? 10)
                    }
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
    
    func setnumber(_ number: String) -> Bool {
        guard number.isEmpty == false else {
            return false
        }
        let verified = verifynumbers(number)
        if verified == true {
            return true
        } else {
            return false
        }
    }

    // Verify number
    func verifynumbers(_ number: String) -> Bool {
        guard number.isEmpty == false else { return false }
        if Int(number) != nil { return true }
        return false
    }
}
