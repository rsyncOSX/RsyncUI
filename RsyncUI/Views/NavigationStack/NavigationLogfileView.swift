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
                TableColumn("Lines") { data in
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
