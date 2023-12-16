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
            Table(logfileview.output) {
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
                    Image(systemName: "eraser")
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

@Observable
final class Logfileview {
    var output = [Data]()

    struct Data: Identifiable {
        let id = UUID()
        var line: String
    }

    func generatedata() {
        output = [Data]()
        let data = Logfile(false).getlogfile()
        guard data.count < 10000 else {
            output.append(Data(line: "Logfile is to big (more than 10000 lines)"))
            output.append(Data(line: "Please reset logfile"))
            return
        }
        for i in 0 ..< data.count {
            output.append(Data(line: data[i]))
        }
    }
}
