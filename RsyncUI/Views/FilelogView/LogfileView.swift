//
//  LogfileView.swift
//  RsyncSwiftUI
//
//  Created by Thomas Evensen on 09/02/2021.
//

import Foundation
import Observation
import SwiftUI

struct LogfileView: View {
    @SwiftUI.Environment(\.dismiss) var dismiss
    @State private var resetloggfile = false
    @State private var logfileview = Logfileview()

    var body: some View {
        VStack {
            Section(header: headerlogfile) {
                Table(logfileview.output) {
                    TableColumn("Logfile") { data in
                        Text(data.line)
                    }
                    .width(min: 700)
                }
                .onChange(of: resetloggfile) {
                    afterareload()
                }
            }

            Spacer()

            HStack {
                Spacer()

                Button("Dismiss") { dismiss() }
                    .buttonStyle(ColorfulButtonStyle())
            }
        }
        .padding()
        .frame(minWidth: 800, minHeight: 400)
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

    var headerlogfile: some View {
        Text("Logfile")
            .modifier(FixedTag(200, .center))
    }

    var headeractions: some View {
        Text("Actions")
            .modifier(FixedTag(200, .center))
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
