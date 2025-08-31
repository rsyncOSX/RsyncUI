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
    @State private var datainchartbool: Bool = true // True files
    @State private var datainchart: DataInChart = .numberoffiles
    @State private var typeofchartbool: Bool = true // True Barchart
    @State private var typeofchart: TypeofChart = .barchart
    @State private var filesormbbool: Bool = true // True files
    @State private var filesormb: FilesOrMB = .files
    @State private var numberofdata: String = ""

    var body: some View {
        VStack {
            
            Text("Statistics: number of data \(logentries?.count ?? 0) ")
                .font(.title)
                .padding(.bottom, 10)
            
            Text(subtitle)
                .font(.title2)
                .padding(.bottom, 10)
            
            HStack {
                
                Toggle("MB or Files", isOn: $datainchartbool)
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
                
                Toggle("Present by MB or Files", isOn: $filesormbbool)
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
                // By default select all dates, one date only if more than one with max files transferred
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
                        logentries = await actorreadchartsdata.getTopNMaxPerDaybyfiles(from: allmaxlogentries, count: Int(numberofdata) ?? 20)
                    }
                    
                } else {
                    if numberofdata.isEmpty {
                        logentries = await actorreadchartsdata.selectMaxValueMBDates(from: parsedlogs)
                    } else {
                        let allmaxlogentries = await actorreadchartsdata.selectMaxValueMBDates(from: parsedlogs)
                        logentries = await actorreadchartsdata.getTopNMaxPerDaybyMB(from: allmaxlogentries, count: Int(numberofdata) ?? 20)
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
        
        var subtitle: String {
            var readdatabyfilesormb = ""
            var presentbyfilesormb = ""
            
            if datainchart == .numberoffiles  {
                readdatabyfilesormb = "Read logrecords by max files,"
            } else {
                readdatabyfilesormb = "Read logrecords by max data (MB),"
            }
            
            if filesormb == .files {
                presentbyfilesormb = "show number of files"
            } else {
                presentbyfilesormb = "show transferred data (MB)"
            }
            
            return "\(readdatabyfilesormb) \(presentbyfilesormb)"
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
