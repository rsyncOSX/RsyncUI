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
    @State private var whichlogfileispresented: LogfileToReset = .rsyncUIlogfile

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
                    text: "Clear",
                    helpText: "Reset logfile"
                ) {
                    reset()
                }
            }
        }
        .padding()
        .task {
            logfilerecords = await ActorCreateOutputforView().createaoutputlogfileforview()
        }
    }

    func reset() {
        Task {
            await ActorLogToFile(whichlogfileispresented)
            logfilerecords = await ActorCreateOutputforView().createaoutputlogfileforview()
        }
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
