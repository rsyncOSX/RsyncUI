//
//  LogfileView.swift
//  RsyncSwiftUI
//
//  Created by Thomas Evensen on 09/02/2021.
//

import Foundation
import SwiftUI

struct LogfileView: View {
    @SwiftUI.Environment(\.dismiss) var dismiss
    @State private var resetloggfile = false
    @State private var showactions = false

    @StateObject private var logfileview = Logfileview()
    var action: Actions

    var body: some View {
        VStack {
            if showactions {
                Section(header: headeractions) {
                    Table(action.output) {
                        TableColumn("Lines") { data in
                            Text(data.line)
                        }
                        .width(min: 700)
                    }
                }
            } else {
                Section(header: headerlogfile) {
                    Table(logfileview.output) {
                        TableColumn("Lines") { data in
                            Text(data.line)
                        }
                        .width(min: 700)
                    }
                    .onChange(of: resetloggfile, perform: { _ in
                        afterareload()
                    })
                }
            }

            Spacer()

            HStack {
                Spacer()

                Button("Actions") {
                    if showactions == false {
                        showactions = true
                        action.generatedata()
                    } else { showactions = false }
                }
                .buttonStyle(PrimaryButtonStyle())

                Button("Reset") { reset() }
                    .buttonStyle(PrimaryButtonStyle())

                Button("Dismiss") { dismiss() }
                    .buttonStyle(PrimaryButtonStyle())
            }
        }
        .padding()
        .frame(minWidth: 600, minHeight: 400)
        .onAppear {
            logfileview.generatedata()
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

final class Logfileview: ObservableObject {
    @Published var output = [Data]()

    struct Data: Identifiable {
        let id = UUID()
        var line: String
    }

    func generatedata() {
        output = [Data]()
        let data = Logfile(false).getlogfile()
        for i in 0 ..< data.count {
            output.append(Data(line: data[i]))
        }
    }
}
