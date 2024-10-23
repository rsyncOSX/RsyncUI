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
    @State private var logfileview = Logfileview()

    var body: some View {
        VStack {
            Table(logfileview.output ?? []) {
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
            logfileview.generatedata()
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
        _ = Logfile(true)
        logfileview.generatedata()
    }

    func afterareload() {
        resetloggfile = false
    }
}

@Observable @MainActor
final class Logfileview: PropogateError {
    var output: [LogfileRecords]?
    let maxcount = 10000

    struct LogfileRecords: Identifiable {
        let id = UUID()
        var line: String
    }

    func validatesizelogfile(data: [String]) throws {
        guard data.count < maxcount else {
            throw LogfileError.toobig
        }
    }
    
    
    func generatedata() {
        let data = Logfile(false).getlogfile()
        do {
            try validatesizelogfile(data: data)
            output = data.map({ record in
                LogfileRecords(line: record)
            })
            
        } catch let e {
            let error = e
            propogateerror(error: error)
            return
        }
    }
}


enum LogfileError: LocalizedError {
    case toobig

    var errorDescription: String? {
        switch self {
        case .toobig:
            "Logfile is to big, more than 10000 lines\n Please reset logfile"
        }
    }
}
