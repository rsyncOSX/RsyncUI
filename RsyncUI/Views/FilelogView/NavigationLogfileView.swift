//
//  NavigationLogfileView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 25/11/2023.
//

import Foundation
import Observation
import SwiftUI

struct NavigationLogfileView: View {
    @State private var resetloggfile = false
    @State private var logfilerecords: [LogfileRecords]?

    var body: some View {
        VStack {
            Table(logfilerecords ?? []) {
                TableColumn("Logfile") { data in
                    Text(data.line)
                }
            }
            .onChange(of: resetloggfile) {
                afterareload()
            }
        }
        .padding()
        .onAppear {
            Task {
                logfilerecords = await GenerateLogfileforview().generatedata()
            }
        }
        .toolbar {
            ToolbarItem {
                Button {
                    reset()
                } label: {
                    Image(systemName: "clear")
                }
                .help("Reset logfile")
            }
        }
    }

    func reset() {
        resetloggfile = true

        Task {
            await ActorLogToFile(true)
            logfilerecords = await GenerateLogfileforview().generatedata()
        }
    }

    func afterareload() {
        resetloggfile = false
    }
}

struct LogfileRecords: Identifiable {
    let id = UUID()
    var line: String
}

@Observable @MainActor
final class Logfileview {
    var output: [LogfileRecords]?
}

import OSLog

actor GenerateLogfileforview {
    @concurrent
    nonisolated func generatedata() async -> [LogfileRecords] {
        Logger.process.info("GenerateLogfileforview: generatedata() MAIN THREAD: \(Thread.isMain) but on \(Thread.current)")
        if let data = await ActorLogToFile(false).readloggfile() {
            return data.map { record in
                LogfileRecords(line: record)
            }
        } else {
            return []
        }
    }
}
