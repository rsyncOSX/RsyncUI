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
    @State private var showactions = false

    @State private var logfileview = Logfileview()
    var action: Actions

    var body: some View {
        VStack {
            if showactions {
                Section(header: headeractions) {
                    Table(action.getactions()) {
                        TableColumn("Num") { data in
                            let num = String(data.actionnumber ?? -1)
                            Text(num)
                        }
                        .width(max: 25)

                        TableColumn("Where", value: \.source)
                            .width(min: 50)

                        TableColumn("Profile", value: \.profile)
                            .width(min: 50)

                        TableColumn("Date") { data in
                            let date = data.timestamp.long_localized_string_from_date()
                            Text(date)
                        }
                        .width(max: 400)

                        TableColumn("Action", value: \.action)
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
                    .onChange(of: resetloggfile) { afterareload() }
                }
            }

            Spacer()

            HStack {
                Spacer()

                Toggle("Actions", isOn: $showactions)
                    .toggleStyle(.switch)

                Button("Reset") { reset() }
                    .buttonStyle(PrimaryButtonStyle())

                Button("Dismiss") { dismiss() }
                    .buttonStyle(PrimaryButtonStyle())
            }
        }
        .padding()
        .frame(minWidth: 800, minHeight: 400)
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
