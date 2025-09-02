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

    @State private var enablefilesorsize: Bool = false

    @State private var numberofdatabool: Bool = false
    @State private var numberofdata: String = ""

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
                    .disabled(!enablefilesorsize)

                Toggle("Line or Bar chart", isOn: $typeofchartbool)
                    .toggleStyle(.switch)
                    .onChange(of: typeofchartbool) {
                        if typeofchartbool {
                            typeofchart = .barchart
                        } else {
                            typeofchart = .linemarkchart
                        }
                    }

                EditValueErrorScheme(50, "Num", $numberofdata, setnumber(numberofdata))

                Toggle("Apply numbers", isOn: $numberofdatabool)
                    .toggleStyle(.switch)
            }

            HStack {
                if typeofchart == .linemarkchart {
                    Chart {
                        ForEach(logentries ?? []) { entry in
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
                                .foregroundStyle(.green)
                                .symbol(by: .value("Type", "Size"))
                            }
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
                    Chart {
                        ForEach(logentries ?? []) { entry in
                            switch datainchart {
                            case .numberoffiles:
                                BarMark(
                                    x: .value("Date", entry.date),
                                    y: .value("Number of Files", entry.files)
                                )
                                .foregroundStyle(.blue)
                                .symbol(by: .value("Type", "Files"))

                            case .transferreddata:
                                BarMark(
                                    x: .value("Date", entry.date),
                                    y: .value("Size (MB)", entry.transferredMB)
                                )
                                .foregroundStyle(.green)
                                .symbol(by: .value("Type", "Size"))
                            }
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
                }

                if let logentries {
                    Table(logentries) {
                        TableColumn("Date") { item in
                            Text(item.date, style: .date)
                        }
                        .alignment(.leading)
                        TableColumn("Size (MB)") { item in
                            Text(String(format: "%.2f", item.transferredMB))
                        }
                        .alignment(.trailing)
                        TableColumn("Files") { item in
                            Text(String(item.files))
                        }
                        .alignment(.trailing)
                    }
                    .padding()
                    .frame(width: 400)
                }
            }
        }
        .padding()
        .onAppear {
            Task {
                logentries = await readandsortlogdata(hiddenID, validhiddenIDs)
            }
        }
        .onChange(of: numberofdatabool) {
            Task {
                logentries = await readandsortlogdata(hiddenID, validhiddenIDs)
            }
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

        var subtitle: String {
            var readdatabyfilesormb = ""

            if enablefilesorsize {
                if datainchart == .numberoffiles {
                    readdatabyfilesormb = "Some multiple dates, isolate date by max files transferred"
                } else {
                    readdatabyfilesormb = "Some multiple dates, isolate date by max size transferred"
                }
            } else {
                readdatabyfilesormb = "Only single dates in logrecords: "
            }

            return readdatabyfilesormb
        }
    }

    private func setnumber(_ number: String) -> Bool {
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
    private func verifynumbers(_ number: String) -> Bool {
        guard number.isEmpty == false else { return false }
        if Int(number) != nil { return true }
        return false
    }

    private func readandsortlogdata(_ hiddenID: Int, _ validhiddenIDs: Set<Int>) async -> [LogEntry] {
        let actorreadlogs = ActorReadLogRecordsJSON()
        let actorreadchartsdata = ActorLogChartsData()
        let logrecords = await actorreadlogs.readjsonfilelogrecords(rsyncUIdata.profile, validhiddenIDs)
        let alllogs = await actorreadlogs.updatelogsbyhiddenID(logrecords, hiddenID) ?? []
        let parsedlogs = await actorreadchartsdata.parselogrecords(from: alllogs)

        if datainchart == .numberoffiles {
            if numberofdata.isEmpty || numberofdatabool == false {
                let allmaxlogentries = await actorreadchartsdata.selectMaxValueFilesDates(from: parsedlogs)
                // Check if more data pr one date
                enablefilesorsize = allmaxlogentries.count != parsedlogs.count
                return allmaxlogentries
            } else {
                enablefilesorsize = false
                let allmaxlogentries = await actorreadchartsdata.selectMaxValueFilesDates(from: parsedlogs)
                return await actorreadchartsdata.getTopNMaxPerDaybyfiles(from: allmaxlogentries, count: Int(numberofdata) ?? 20)
            }

        } else {
            if numberofdata.isEmpty || numberofdatabool == false {
                let allmaxlogentries = await actorreadchartsdata.selectMaxValueMBDates(from: parsedlogs)
                // Check if more data pr one date
                enablefilesorsize = allmaxlogentries.count != parsedlogs.count
                return allmaxlogentries
            } else {
                enablefilesorsize = false
                let allmaxlogentries = await actorreadchartsdata.selectMaxValueMBDates(from: parsedlogs)
                return await actorreadchartsdata.getTopNMaxPerDaybyMB(from: allmaxlogentries, count: Int(numberofdata) ?? 20)
            }
        }
    }
}
