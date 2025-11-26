//
//  NavigationLogfileView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 25/11/2023.
//

import Foundation
import Observation
import SwiftUI

struct LogfileView: View {
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
            
            Spacer()
            
            HStack {
                
                ConditionalGlassButton(
                    systemImage: "document",
                    text: "Logfile",
                    helpText: "View logfile"
                ) {
                    Task {
                        logfilerecords = await ActorCreateOutputforView().createaoutputlogfileforview()
                    }
                }
                
                ConditionalGlassButton(
                    systemImage: "square.and.arrow.down.badge.checkmark",
                    text: "Rsync output",
                    helpText: "View rsync output"
                ) {
                    Task {
                        logfilerecords = await ActorCreateOutputforView().createaoutputrsynclogforview()
                    }
                }
                
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
        resetloggfile = true

        Task {
            await ActorLogToFile(true)
            logfilerecords = await ActorCreateOutputforView().createaoutputlogfileforview()
        }
    }

    func afterareload() {
        resetloggfile = false
    }
    
    func readlogfile()  {
        Task {
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
