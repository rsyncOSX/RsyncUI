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
    @StateObject private var logfileview = Logfileview()

    var body: some View {
        VStack {
            Section(header: headerlogfile) {
                Table(logfileview.output) {
                    TableColumn("Lines") { data in
                        Text(data.line)
                    }
                    .width(min: 700)
                }
                .onChange(of: resetloggfile) { _ in
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
