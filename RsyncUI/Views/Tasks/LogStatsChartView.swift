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
    case numberoffiles
    case transferreddata

    var id: String { rawValue }
    var description: String { rawValue.localizedLowercase }
}

enum TypeofChart: String, CaseIterable, Identifiable, CustomStringConvertible {
    case linemarkchart
    case barchart

    var id: String { rawValue }
    var description: String { rawValue.localizedLowercase }
}

struct LogStatsChartView: View {
    @Bindable var rsyncUIdata: RsyncUIconfigurations
    @Binding var selecteduuids: Set<SynchronizeConfiguration.ID>

    @State private var logentries: [LogEntry]?

    @State private var datainchartbool: Bool = true // True files
    @State private var datainchart: DataInChart = .numberoffiles

    @State private var typeofchartbool: Bool = true // True Barchart
    @State private var typeofchart: TypeofChart = .barchart

    @State private var numberofdatabool: Bool = false
    @State private var numberofdata: String = ""

    @State private var selectedDataPoint: LogEntry.ID?
    // Read and prepare chardata
    @State private var chartdata = ObservableChartData()

    var body: some View {
        VStack {
            Text("Statistics: number of records in chart \(logentries?.count ?? 0) for \(synchronizeid)")
                .font(.title)
                .padding(.bottom, 10)

            Text(subtitle)
                .font(.title2)
                .padding(.bottom, 10)

            HStack {
                Toggle("Size or Files", isOn: $datainchartbool)
                    .toggleStyle(.switch)
                    .onChange(of: datainchartbool) {
                        if datainchartbool {
                            datainchart = .numberoffiles
                        } else {
                            datainchart = .transferreddata
                        }
                    }

                Toggle("Line or Bar", isOn: $typeofchartbool)
                    .toggleStyle(.switch)
                    .onChange(of: typeofchartbool) {
                        if typeofchartbool {
                            typeofchart = .barchart
                        } else {
                            typeofchart = .linemarkchart
                        }
                    }

                EditValueErrorScheme(50, "Num", $numberofdata, setNumber(numberofdata))

                Toggle("Apply selection", isOn: $numberofdatabool)
                    .toggleStyle(.switch)
            }

            HStack {
                if typeofchart == .linemarkchart {
                    Chart(logentries ?? []) { entry in
                        switch datainchart {
                        case .numberoffiles:
                            LineMark(
                                x: .value("Date", entry.date),
                                y: .value("Number of Files", entry.files)
                            )
                            .foregroundStyle(.blue)
                            .symbol(by: .value("Type", "Files"))
                        case .transferreddata:
                            LineMark(
                                x: .value("Date", entry.date),
                                y: .value("Size (MB)", entry.transferredMB)
                            )
                            .foregroundStyle(.blue)
                            .symbol(by: .value("Type", "Size"))
                        }
                    }
                    .chartXAxis {
                        AxisMarks(preset: .aligned, position: .bottom) { _ in
                            AxisValueLabel()
                            AxisTick()
                        }
                    }
                    .chartYAxis {
                        AxisMarks(position: .leading) { _ in
                            AxisValueLabel()
                        }
                    }
                    .padding()
                } else {
                    Chart(logentries ?? []) { entry in
                        switch datainchart {
                        case .numberoffiles:
                            BarMark(
                                x: .value("Date", entry.date),
                                y: .value("Number of Files", entry.files)
                            )
                            .symbol(by: .value("Type", "Files"))
                            .foregroundStyle(selectedDataPoint == entry.id ? .red : .blue)
                            .opacity(selectedDataPoint == nil || selectedDataPoint == entry.id ? 1.0 : 0.5)

                        case .transferreddata:
                            BarMark(
                                x: .value("Date", entry.date),
                                y: .value("Size (MB)", entry.transferredMB)
                            )
                            .symbol(by: .value("Type", "Size"))
                            .foregroundStyle(selectedDataPoint == entry.id ? .red : .green)
                            .opacity(selectedDataPoint == nil || selectedDataPoint == entry.id ? 1.0 : 0.5)
                        }
                    }
                    .chartXAxis {
                        AxisMarks(preset: .aligned, position: .bottom) { _ in
                            AxisValueLabel()
                        }
                    }
                    .chartYAxis {
                        AxisMarks(position: .leading) { _ in
                            AxisValueLabel()
                        }
                    }
                    .padding()
                }

                if let logentries {
                    Table(logentries, selection: $selectedDataPoint) {
                        TableColumn("Date") { item in
                            Text(item.date, style: .date)
                        }
                        .alignment(.leading)
                        TableColumn("Size (MB)") { item in
                            if datainchart == .transferreddata, selectedDataPoint != nil, typeofchart == .barchart {
                                Text(String(format: "%.2f", item.transferredMB))
                                    .foregroundColor(.red)
                            } else {
                                Text(String(format: "%.2f", item.transferredMB))
                            }
                        }
                        .alignment(.trailing)
                        TableColumn("Files") { item in
                            if datainchart == .numberoffiles, selectedDataPoint != nil, typeofchart == .barchart {
                                Text(String(item.files))
                                    .foregroundColor(.red)
                            } else {
                                Text(String(item.files))
                            }
                        }
                        .alignment(.trailing)
                    }
                    .padding()
                    .frame(width: 400)
                }
            }
        }
        .padding()
        .task {
            await chartdata.readandparselogs(profile: rsyncUIdata.profile,
                                             validhiddenIDs: validhiddenIDs,
                                             hiddenID: hiddenID)

            logentries = await readAndSortLogData()
        }
        .task(id: numberofdatabool) {
            logentries = await readAndSortLogData()
        }
        .task(id: datainchart) {
            logentries = await readAndSortLogData()
        }

        var synchronizeid: String {
            if let configurations = rsyncUIdata.configurations {
                if let index = configurations.firstIndex(where: { $0.id == selecteduuids.first }) {
                    return configurations[index].backupID
                } else {
                    return ""
                }
            }
            return ""
        }

        var validhiddenIDs: Set<Int> {
            var temp = Set<Int>()
            if let configurations = rsyncUIdata.configurations {
                for config in configurations {
                    temp.insert(config.hiddenID)
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

        var subtitle: String {
            var readdatabyfilesormb = ""

            if datainchart == .numberoffiles {
                readdatabyfilesormb = "Records by files transferred..."
            } else {
                readdatabyfilesormb = "Records by max size transferred..."
            }

            return readdatabyfilesormb
        }
    }

    private func setNumber(_ number: String) -> Bool {
        guard number.isEmpty == false else {
            return false
        }
        let verified = verifyNumbers(number)
        if verified == true {
            return true
        } else {
            return false
        }
    }

    // Verify number
    private func verifyNumbers(_ number: String) -> Bool {
        guard number.isEmpty == false else { return false }
        if Int(number) != nil { return true }
        return false
    }

    private func readAndSortLogData() async -> [LogEntry] {
        let actorreadchartsdata = ActorLogChartsData()

        if let parsedlogs = chartdata.parsedlogs {
            if datainchart == .numberoffiles {
                if numberofdata.isEmpty || numberofdatabool == false {
                    let allmaxlogentries = await actorreadchartsdata.parsemaxfilesbydate(from: parsedlogs)
                    // Check if more data pr one date
                    return allmaxlogentries
                } else {
                    let allmaxlogentries = await actorreadchartsdata.parsemaxfilesbydate(from: parsedlogs)
                    return await actorreadchartsdata.parsemaxNNfilesbydate(from: allmaxlogentries, count: Int(numberofdata) ?? 20)
                }
            } else {
                if numberofdata.isEmpty || numberofdatabool == false {
                    let allmaxlogentries = await actorreadchartsdata.parsemaxfilesbytransferredsize(from: parsedlogs)
                    // Check if more data pr one date
                    return allmaxlogentries
                } else {
                    let allmaxlogentries = await actorreadchartsdata.parsemaxfilesbytransferredsize(from: parsedlogs)
                    return await actorreadchartsdata.parsemaxNNfilesbytransferredsize(from: allmaxlogentries,
                                                                                      count: Int(numberofdata) ?? 20)
                }
            }
        }
        return []
    }
}
