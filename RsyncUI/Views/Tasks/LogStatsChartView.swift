//
//  LogStatsChartView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 29/08/2025.
//

import Charts
import SwiftUI

enum DataInChart: String, CaseIterable, Identifiable, CustomStringConvertible {
    case numberoffiles
    case transferreddata

    var id: String {
        rawValue
    }

    var description: String {
        rawValue.localizedLowercase
    }
}

enum TypeofChart: String, CaseIterable, Identifiable, CustomStringConvertible {
    case linemarkchart
    case barchart

    var id: String {
        rawValue
    }

    var description: String {
        rawValue.localizedLowercase
    }
}

struct LogStatsChartView: View {
    @Bindable var rsyncUIdata: RsyncUIconfigurations
    @Binding var selecteduuids: Set<SynchronizeConfiguration.ID>

    @State private var logentries = [LogEntry]()

    @State private var datainchartbool: Bool = true // True files
    @State private var datainchart: DataInChart = .numberoffiles

    @State private var typeofchartbool: Bool = true // True Barchart
    @State private var typeofchart: TypeofChart = .barchart

    @State private var numberofdata: String = ""

    @State private var selectedDataPoint: LogEntry.ID?

    var body: some View {
        VStack {
            Text("Statistics: number of records in chart \(logentries.count) for \(synchronizeid)")
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

                EditValueErrorScheme(100, "Records", $numberofdata, setNumber(numberofdata))
            }

            HStack {
                if typeofchart == .linemarkchart {
                    Chart(logentries) { entry in
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
                    Chart(logentries) { entry in
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

                Table(logentries, selection: $selectedDataPoint) {
                    TableColumn("Date") { item in
                        Text(item.date, style: .date)
                    }
                    .alignment(.leading)
                    TableColumn("Size (MB)") { item in
                        if datainchart == .transferreddata, selectedDataPoint != nil, typeofchart == .barchart {
                            Text(String(format: "%.2f", item.transferredMB))
                                .foregroundStyle(.red)
                        } else {
                            Text(String(format: "%.2f", item.transferredMB))
                        }
                    }
                    .alignment(.trailing)
                    TableColumn("Files") { item in
                        if datainchart == .numberoffiles, selectedDataPoint != nil, typeofchart == .barchart {
                            Text(String(item.files))
                                .foregroundStyle(.red)
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
        .padding()
        .task(id: chartRefreshKey) {
            await reloadChartData()
        }

        var synchronizeid: String {
            rsyncUIdata.configurations?.backupID(for: selecteduuids.first) ?? ""
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

    private var chartMetric: LogChartMetric {
        switch datainchart {
        case .numberoffiles:
            .files
        case .transferreddata:
            .transferredMB
        }
    }

    private var chartLimit: LogChartLimit {
        guard numberofdata.isEmpty == false else {
            return .maxPerDay
        }

        return .topNPerDay(Int(numberofdata) ?? 20)
    }

    private var chartRefreshKey: ChartRefreshKey {
        ChartRefreshKey(
            profile: rsyncUIdata.profile,
            selectedConfigurationID: selecteduuids.first,
            metric: chartMetric,
            limit: chartLimit,
            configurations: (rsyncUIdata.configurations ?? []).map {
                ConfigurationKey(id: $0.id, hiddenID: $0.hiddenID)
            }
        )
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

    /// Verify number
    private func verifyNumbers(_ number: String) -> Bool {
        guard number.isEmpty == false else { return false }
        if Int(number) != nil { return true }
        return false
    }

    private func reloadChartData() async {
        let entries = await LogStoreService.chartEntries(
            profile: rsyncUIdata.profile,
            configurations: rsyncUIdata.configurations,
            configurationID: selecteduuids.first,
            metric: chartMetric,
            limit: chartLimit
        )

        if logentries != entries {
            logentries = entries
        }

        if let selectedDataPoint,
           entries.contains(where: { $0.id == selectedDataPoint }) == false {
            self.selectedDataPoint = nil
        }
    }
}

private struct ConfigurationKey: Equatable {
    let id: SynchronizeConfiguration.ID
    let hiddenID: Int
}

private struct ChartRefreshKey: Equatable {
    let profile: String?
    let selectedConfigurationID: SynchronizeConfiguration.ID?
    let metric: LogChartMetric
    let limit: LogChartLimit
    let configurations: [ConfigurationKey]
}
