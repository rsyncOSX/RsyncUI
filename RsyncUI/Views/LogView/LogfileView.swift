//
//  LogfileView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 25/11/2023.
//

import Foundation
import Observation
import SwiftUI

struct LogfileView: View {
    @State private var logfilerecords: [LogfileRecords]?

    var body: some View {
        VStack {
            Table(logfilerecords ?? []) {
                TableColumn("Logfile") { data in
                    Text(data.line)
                }
            }

            Spacer()

            HStack {
                Spacer()

                ConditionalGlassButton(
                    systemImage: "trash",
                    text: "Reset",
                    helpText: "Reset logfile"
                ) {
                    Task {
                        await reset()
                    }
                }
            }
        }
        .padding()
        .task {
            await loadLogfile()
        }
    }

    @MainActor
    private func loadLogfile() async {
        logfilerecords = await CreateOutputforView().createaoutputlogfileforview()
    }

    @MainActor
    private func reset() async {
        await ActorLogToFile().reset()
        await loadLogfile()
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
