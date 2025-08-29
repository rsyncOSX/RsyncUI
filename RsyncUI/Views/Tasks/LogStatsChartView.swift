//
//  LogStatsChartView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 29/08/2025.
//

import SwiftUI
import Charts

// MARK: - Model for log data
struct LogEntry: Identifiable {
    let id = UUID()
    let date: Date
    let numFiles: Int
    let dataTransferredMB: Double
}

// MARK: - Sample data
let sampleLogData: [LogEntry] = [
    LogEntry(date: Date(timeIntervalSinceNow: -86400*5), numFiles: 120, dataTransferredMB: 500),
    LogEntry(date: Date(timeIntervalSinceNow: -86400*4), numFiles: 200, dataTransferredMB: 1100),
    LogEntry(date: Date(timeIntervalSinceNow: -86400*3), numFiles: 150, dataTransferredMB: 700),
    LogEntry(date: Date(timeIntervalSinceNow: -86400*2), numFiles: 300, dataTransferredMB: 1300),
    LogEntry(date: Date(timeIntervalSinceNow: -86400*1), numFiles: 170, dataTransferredMB: 850)
]

// MARK: - SwiftUI Chart View
struct LogStatsChartView: View {
    let logEntries: [LogEntry]

    var body: some View {
        VStack {
            Text("Rsync Log Statistics")
                .font(.title)
                .padding(.bottom, 10)
            
            Chart {
                ForEach(logEntries) { entry in
                    LineMark(
                        x: .value("Date", entry.date),
                        y: .value("Number of Files", entry.numFiles)
                    )
                    .foregroundStyle(.blue)
                    .symbol(by: .value("Type", "Files"))
                    
                    LineMark(
                        x: .value("Date", entry.date),
                        y: .value("Data Transferred (MB)", entry.dataTransferredMB)
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
    }
}

